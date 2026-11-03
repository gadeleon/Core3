-- Nirame Sakute: which screen a pilot opens on (gate table G0 .. G19), the helpers, the duty menu, the first meeting and the off-track menu; invariant I-9.
-- Spec: .claude/work/smuggler-tier4-nirame/01-spec.md (AC-7, AC-8; Conversation flow 1, 2, 3 and 5; Content contract 3; D-8, D-9, D-10, D-19, D-20, D-21; I-9).
--
-- One test per gate row: a pilot built to satisfy that row and none above it opens on the listed screen. The builder is smuggler_tier4_data.lua N.pilot
-- (default: a Smuggler tier 3 graduate at pilot tier 4 with no tier 4 state). Every first-screen call is wrapped by `opens`, which also proves that
-- getInitialScreen changes nothing (I-9: no quest start, journal write, :attempted key, skill, credit, item or pilot tier change).

local lu = require("luaunit")
local H = require("harness")
local N = require("smuggler_tier4_data")
local CS = require("harness.client_strings")

N.load()

local ALL = { 1, 2, 3, 4 }
local G = N.GLOBALS
local XP = 1000000

local function handler() return rawget(_G, N.HANDLER) end

TestSmugglerT4Gates = {}

function TestSmugglerT4Gates:setUp()
	H.reset()
	N.requireConversation(lu)
end

-- the id of the screen getInitialScreen picks, with a proof that the call changes nothing (I-9). The screen handlers of the talk are not run (a reward
-- screen pays on display), so this is the gate alone.
local function opens(player, label)
	local before = N.snapshot(player)
	local pScreen = handler():getInitialScreen(player, N.npc(), H.conversationTemplate(N.TEMPLATE))

	lu.assertNotNil(pScreen, (label or "gate") .. ": getInitialScreen returns a screen")
	lu.assertEquals(N.snapshot(player), before, (label or "gate") .. ": getInitialScreen changes nothing (I-9)")

	return LuaConversationScreen(pScreen):getScreenID()
end

-- n skills (the first n of N.TRAIN) and the first n missions paid
local function done(n)
	local t4, paid = {}, {}

	for i = 1, n do
		t4[i], paid[i] = i, i
	end

	return t4, paid
end

-- G0
-- AC-7
function TestSmugglerT4Gates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = N.pilot(), N.npc(), H.conversationTemplate(N.TEMPLATE)

	lu.assertNil(handler():getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(handler():getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(handler():getInitialScreen(player, npc, nil), "no template")
end

-- G1 (D-9)
-- AC-7
function TestSmugglerT4Gates:test_jtl_disabled_opens_not_neutral()
	H.Engine.config.jtlEnabled = false
	lu.assertEquals(opens(N.pilot(), "JTL disabled"), "not_neutral", "JTL disabled")
	lu.assertEquals(opens(N.pilot({ mission = { [1] = "won" } }), "JTL disabled, mission won"), "not_neutral", "JTL disabled beats every later row")
end

-- G1
-- AC-7
function TestSmugglerT4Gates:test_a_pilot_without_a_player_object_opens_not_neutral()
	local player = N.pilot()

	player.ghost = nil

	local pScreen = handler():getInitialScreen(player, N.npc(), H.conversationTemplate(N.TEMPLATE))

	lu.assertEquals(LuaConversationScreen(pScreen):getScreenID(), "not_neutral", "ghost is nil")
end

-- G2
-- AC-7
function TestSmugglerT4Gates:test_non_pilots_and_rebel_and_imperial_pilots_open_not_neutral()
	lu.assertEquals(opens(N.pilot({ pilot = false, squadron = false }), "non-pilot"), "not_neutral", "no pilot skills")
	lu.assertEquals(opens(N.pilot({ pilot = "rebel", squadron = false }), "rebel pilot"), "not_neutral", "a Rebel pilot")
	lu.assertEquals(opens(N.pilot({ pilot = "imperial", squadron = false }), "imperial pilot"), "not_neutral", "an Imperial pilot")
	lu.assertEquals(opens(N.pilot({ pilot = "rebel", faction = "rebel", squadron = false }), "rebel pilot with faction"), "not_neutral", "a Rebel pilot of the Rebel faction")
	lu.assertEquals(opens(N.pilot({ pilot = "imperial", faction = "imperial", squadron = false }), "imperial pilot with faction"), "not_neutral", "an Imperial pilot of the Imperial faction")
end

-- G3
-- AC-7
function TestSmugglerT4Gates:test_corsec_rsf_and_squadronless_neutral_pilots_open_off_track()
	lu.assertEquals(opens(N.pilot({ squadron = CORSEC_SQUADRON }), "CorSec"), "off_track", "a CorSec pilot")
	lu.assertEquals(opens(N.pilot({ squadron = RSF_SQUADRON }), "RSF"), "off_track", "an RSF pilot")
	lu.assertEquals(opens(N.pilot({ squadron = false }), "squadron-less"), "off_track", "a neutral pilot without a squadron")
	lu.assertEquals(opens(N.pilot({ squadron = CORSEC_SQUADRON, mission = { [1] = "won" } }), "CorSec with Smuggler state"), "off_track", "off-track beats the not-ready and mission rows")
	lu.assertEquals(opens(N.pilot({ squadron = CORSEC_SQUADRON, t3 = {} }), "CorSec without tier 3"), "off_track", "off-track beats not-ready")
end

-- G4
-- AC-7
function TestSmugglerT4Gates:test_a_smuggler_without_the_four_tier_3_skills_opens_not_ready()
	lu.assertEquals(opens(N.pilot({ t3 = {} }), "no tier 3"), "not_ready", "a Smuggler with no _03 skill")

	for i = 1, 4 do
		local have = {}

		for k = 1, 4 do
			if k ~= i then
				have[#have + 1] = k
			end
		end

		H.reset()
		lu.assertEquals(opens(N.pilot({ t3 = have }), "_03 skill " .. i .. " missing"), "not_ready", "three _03 skills (skill " .. i .. " missing)")
	end

	H.reset()
	lu.assertEquals(opens(N.pilot({ t3 = { 1, 2, 3 }, t4 = ALL, paid = ALL }), "tier 4 skills without the tier 3 ones"), "not_ready", "the _04 skills do not replace a _03 skill")
end

-- G4: the gate reads the skills, not the pilot tier or earlier missions
-- AC-7
function TestSmugglerT4Gates:test_the_tier_3_gate_ignores_the_pilot_tier_and_the_tier_3_missions()
	for _, tier in ipairs({ 2, 3, 4 }) do
		H.reset()
		lu.assertEquals(opens(N.pilot({ pilotTier = tier }), "pilot tier " .. tier), "intro", "four _03 skills at pilot tier " .. tier)
	end

	H.reset()
	lu.assertEquals(opens(N.pilot({ t2 = false }), "nothing of tier 2"), "intro", "four _03 skills, nothing else")
end

-- G5 (D-20)
-- AC-7
function TestSmugglerT4Gates:test_a_running_mission_a_running_duty_or_any_datapad_space_quest_opens_busy()
	for n = 1, 4 do
		H.reset()
		lu.assertEquals(opens(N.pilot({ mission = { [n] = "active" } }), "mission " .. n .. " running"), "busy", "mission " .. n .. " running (head active)")
	end

	for n, m in ipairs(N.MISSIONS) do
		H.reset()

		local player = N.pilot({ mission = { [n] = "attempted" } })

		N.setState(player, m.chain[#m.chain], "active")
		lu.assertEquals(opens(player, "chain end active"), "busy", "mission " .. n .. ": only the last chain member is active")
	end

	for _, duty in ipairs(N.DUTIES) do
		H.reset()
		lu.assertEquals(opens(N.pilot({ duty4 = duty }), duty), "busy", duty .. " running")
	end

	lu.assertEquals(opens(N.pilot({ datapad = "story" }), "story in datapad"), "busy", "a story mission in the datapad")
	lu.assertEquals(opens(N.pilot({ datapad = "duty" }), "duty in datapad"), "busy", "a duty in the datapad (another trainer's)")
end

-- G5: the failure child of 3b counts as running (the chain walk includes it)
-- AC-7, AC-5
function TestSmugglerT4Gates:test_the_surprise_attack_child_of_mission_3_keeps_the_pilot_busy()
	local player = N.pilot({ mission = { [3] = "attempted" } })

	N.setState(player, G[8], "active")
	lu.assertEquals(opens(player, "3c_sa running"), "busy", "mission 3 with only the failure child running")
	lu.assertTrue(handler():isActive(player, 3), "isActive(3) is true while 3c_sa runs")
	lu.assertFalse(handler():isFailed(player, 3), "isFailed(3) is false while 3c_sa runs")
end

-- G5 above G6 .. G19
-- AC-7
function TestSmugglerT4Gates:test_busy_comes_before_failures_rewards_and_the_rest()
	lu.assertEquals(opens(N.pilot({ mission = { [1] = "won", [2] = "active" } })), "busy", "mission 1 won and unpaid, mission 2 running")
	lu.assertEquals(opens(N.pilot({ t4 = { 1 }, paid = { 1 }, mission = { [2] = "failed", [3] = "active" } })), "busy", "mission 2 failed, mission 3 running")
	lu.assertEquals(opens(N.pilot({ datapad = "story", mission = { [1] = "failed" } })), "busy", "mission 1 failed, a datapad quest")
	lu.assertEquals(opens(N.pilot({ datapad = "duty", mission = { [1] = "won" } })), "busy", "mission 1 won, a duty in the datapad")
	lu.assertEquals(opens(N.pilot({ t4 = ALL, paid = ALL, met = true, datapad = "story" })), "busy", "everything done, a datapad quest")
	lu.assertEquals(opens(N.pilot({ xp = XP, datapad = "story" })), "busy", "enough XP for training, a datapad quest")
	lu.assertEquals(opens(N.pilot({ t4 = ALL, paid = ALL, master = true, duty4 = G[13] })), "busy", "master, a Nirame duty running")
end

-- G5: the busy line has two replies, both end the conversation
-- AC-7
function TestSmugglerT4Gates:test_busy_walks_to_its_endings_and_grants_nothing()
	local player = N.pilot({ mission = { [2] = "active" } })
	local before = N.snapshot(player)

	local t = N.talk(player, { "s_a30c1a53" })

	lu.assertEquals(N.ids(t), { "busy", "busy_back" }, "busy -> back")
	lu.assertTrue(t[2].stop, "busy_back ends")

	t = N.talk(player, { "s_f8e8f311" })
	lu.assertEquals(N.ids(t), { "busy", "busy_work" }, "busy -> work")
	lu.assertTrue(t[2].stop, "busy_work ends")
	lu.assertEquals(N.snapshot(player), before, "the busy dialogue changes nothing")
end

-- G6 .. G9: failed (attempted, not won, not running) and aborted look the same
-- AC-7
function TestSmugglerT4Gates:test_a_failed_or_aborted_mission_opens_its_failed_screen()
	for n = 1, 4 do
		local t4, paid = done(n - 1)

		for _, state in ipairs({ "attempted", "partial" }) do
			H.reset()
			lu.assertEquals(opens(N.pilot({ t4 = t4, paid = paid, mission = { [n] = state } }), "mission " .. n .. " " .. state), "m" .. n .. "_failed", "mission " .. n .. " " .. state)
		end

		-- aborted: it was running, then the journal entry went away
		H.reset()

		local player = N.pilot({ t4 = t4, paid = paid, mission = { [n] = "active" } })

		N.setState(player, N.MISSIONS[n].head, "none")
		lu.assertEquals(opens(player, "mission " .. n .. " aborted"), "m" .. n .. "_failed", "mission " .. n .. " aborted")
	end
end

-- G6 .. G9, D-14: mission 3 failed by leaving the zone (3b ended without a split) is a failure too
-- AC-7, AC-5
function TestSmugglerT4Gates:test_mission_3_with_inspect_and_assassinate_done_but_recovery_unfinished_is_failed()
	local player = N.pilot({ mission = { [3] = "attempted" } })

	N.setState(player, G[6], "complete")
	N.setState(player, G[7], "none")
	lu.assertEquals(opens(player, "3a complete, 3b gone"), "m3_failed", "3a complete, nothing running")
	lu.assertTrue(handler():isFailed(player, 3), "isFailed(3)")
	N.setState(player, G[8], "complete")
	lu.assertEquals(opens(player, "3c_sa complete, 3c never started"), "m3_failed", "3c_sa complete and 3c not complete is a failed mission")
end

-- G6 .. G9: the lowest failed mission first; failed beats reward
-- AC-7
function TestSmugglerT4Gates:test_a_failed_mission_comes_before_a_reward_and_the_lowest_failed_one_first()
	lu.assertEquals(opens(N.pilot({ mission = { [1] = "failed", [2] = "won" } })), "m1_failed", "mission 1 failed, mission 2 won")
	lu.assertEquals(opens(N.pilot({ t4 = { 1 }, paid = { 1 }, mission = { [2] = "failed", [3] = "failed" } })), "m2_failed", "missions 2 and 3 failed")
	lu.assertEquals(opens(N.pilot({ mission = { [1] = "won", [2] = "failed" } })), "m2_failed", "mission 1 won and unpaid, mission 2 failed: m2_failed before m1_reward")
	lu.assertEquals(opens(N.pilot({ mission = { [1] = "won", [4] = "failed" } })), "m4_failed", "mission 1 won and unpaid, mission 4 failed: failed first")
	lu.assertEquals(opens(N.pilot({ mission = { [1] = "failed", [2] = "failed" } })), "m1_failed", "missions 1 and 2 failed")
end

-- G10 .. G13
-- AC-7
function TestSmugglerT4Gates:test_a_won_unpaid_mission_opens_its_reward_screen()
	for n = 1, 4 do
		local t4, paid = done(n - 1)

		H.reset()
		lu.assertEquals(opens(N.pilot({ t4 = t4, paid = paid, mission = { [n] = "won" } }), "mission " .. n .. " won"), "m" .. n .. "_reward", "mission " .. n .. " won, unpaid")
	end
end

-- G10 .. G13: the smallest unpaid won mission first; a paid mission shows no reward screen
-- AC-7
function TestSmugglerT4Gates:test_the_smallest_unpaid_won_mission_comes_first_and_a_paid_one_shows_none()
	lu.assertEquals(opens(N.pilot({ mission = { [1] = "won", [2] = "won" } })), "m1_reward", "missions 1 and 2 won, nothing paid")
	lu.assertEquals(opens(N.pilot({ t4 = { 1 }, paid = { 1 }, mission = { [2] = "won", [3] = "won" } })), "m2_reward", "mission 1 paid, 2 and 3 won")
	lu.assertEquals(opens(N.pilot({ t4 = { 1, 2, 3 }, paid = { 1, 2 }, mission = { [3] = "won", [4] = "won" } })), "m3_reward", "missions 1 and 2 paid, 3 and 4 won")
	lu.assertEquals(opens(N.pilot({ t4 = ALL, paid = { 1, 2, 3 }, mission = { [4] = "won" } })), "m4_reward", "mission 4 won and unpaid with four skills: the reward comes before transfer")
	lu.assertEquals(opens(N.pilot({ t4 = ALL, paid = { 1, 2, 3 }, mission = { [4] = "won" }, met = true, master = true })), "m4_reward", "and before here_for_work")
end

-- G10 .. G13: a mission won by its chain end alone (no :attempted) is won as far as the gates go
-- AC-7
function TestSmugglerT4Gates:test_a_mission_won_by_its_chain_end_alone_has_its_reward_waiting()
	lu.assertEquals(opens(N.pilot({ mission = { [1] = "endonly" } })), "m1_reward", "only the end of mission 1 complete: won, the reward is waiting")
	lu.assertEquals(opens(N.pilot({ mission = { [3] = "endonly" } })), "m3_reward", "only recovery 3c complete: mission 3 won")
end

-- G14 (D-4)
-- AC-7
function TestSmugglerT4Gates:test_the_next_mission_is_ready_when_the_skill_count_reaches_its_number()
	for n = 1, 4 do
		local t4, paid = done(n - 1)

		t4[#t4 + 1] = n
		H.reset()
		lu.assertEquals(opens(N.pilot({ t4 = t4, paid = paid }), "mission " .. n .. " ready"), "ready", n .. " skills, missions 1.." .. (n - 1) .. " paid, mission " .. n .. " not attempted")
	end

	H.reset()
	lu.assertEquals(opens(N.pilot({ t4 = ALL, paid = { 1, 2, 3 } }), "four skills, mission 4 unattempted"), "ready", "four _04 skills with mission 4 unattempted: ready, not transfer")
	lu.assertEquals(opens(N.pilot({ t4 = ALL, paid = { 1, 2, 3 }, met = true, master = true }), "master with mission 4 unattempted"), "ready", "ready beats here_for_work")
end

-- G14: not ready with too few skills, or an attempted mission
-- AC-7
function TestSmugglerT4Gates:test_the_mission_is_not_ready_with_too_few_skills_or_once_attempted()
	-- mission 2 is next, one skill: no
	lu.assertEquals(opens(N.pilot({ t4 = { 1 }, paid = { 1 } }), "one skill, mission 2 next"), "intro", "one skill, mission 1 paid: mission 2 is not ready and there is no XP")
	-- mission 1 attempted and failed: failed screen, not ready
	lu.assertEquals(opens(N.pilot({ t4 = { 1 }, mission = { [1] = "attempted" } }), "mission 1 attempted"), "m1_failed", "attempted")
end

-- G15 (C-1)
-- AC-7
function TestSmugglerT4Gates:test_enough_xp_and_no_ready_mission_opens_ready_train()
	lu.assertEquals(opens(N.pilot({ xp = XP }), "1,000,000 XP"), "ready_train", "no _04 skill, 1,000,000 XP")
	lu.assertEquals(opens(N.pilot({ xp = XP + 5 }), "more XP"), "ready_train", "more XP")

	for n = 1, 3 do
		local t4, paid = done(n)

		H.reset()
		lu.assertEquals(opens(N.pilot({ xp = XP, t4 = t4, paid = paid }), n .. " skills, missions paid"), "ready_train", n .. " skills with mission " .. n .. " paid and the next not ready: the next skill is offered")
	end
end

-- G15: below the XP, or when a mission is ready, there is no training
-- AC-7
function TestSmugglerT4Gates:test_no_training_below_the_xp_with_a_ready_mission_or_after_tier_4()
	lu.assertEquals(opens(N.pilot({ xp = XP - 1 }), "999,999 XP"), "intro", "one XP short")
	lu.assertEquals(opens(N.pilot({ xp = XP, t4 = { 1 } }), "ready mission 1"), "ready", "the ready mission comes first")
	lu.assertEquals(opens(N.pilot({ xp = XP, t4 = ALL, paid = ALL, met = true }), "tier 4 done"), "transfer", "four skills: no more training")
end

-- G16
-- AC-7, AC-8
function TestSmugglerT4Gates:test_a_pilot_who_has_not_met_nirame_opens_intro()
	lu.assertEquals(opens(N.pilot(), "nothing met"), "intro", "no met key")
	lu.assertEquals(opens(N.pilot({ t4 = { 1 }, paid = { 1 } }), "one skill"), "intro", "no met key with one skill and mission 1 paid")
	lu.assertEquals(opens(N.pilot({ t4 = ALL, paid = ALL }), "everything done, never met"), "intro", "R-9: the met gate (G16) is above tier 4 incomplete, transfer and here_for_work")
end

-- G17
-- AC-7
function TestSmugglerT4Gates:test_a_pilot_who_met_nirame_and_is_not_through_tier_4_opens_tier4_incomplete()
	lu.assertEquals(opens(N.pilot({ met = true }), "met"), "tier4_incomplete", "met, no skill")
	lu.assertEquals(opens(N.pilot({ met = true, t4 = { 1 }, paid = { 1 } }), "met, one skill, mission 1 paid"), "tier4_incomplete", "met, one skill, next mission not ready, no XP")

	for _, count in ipairs({ 1, 2, 3 }) do
		local t4, paid = done(count)

		H.reset()
		lu.assertEquals(opens(N.pilot({ met = true, t4 = t4, paid = paid }), count .. " skills"), "tier4_incomplete", count .. " skills, " .. count .. " missions paid")
	end
end

-- G18 (D-19)
-- AC-7, AC-11
function TestSmugglerT4Gates:test_a_tier_4_graduate_without_the_master_skill_opens_transfer_on_every_talk()
	local player = N.pilot({ met = true, t4 = ALL, paid = ALL })

	for i = 1, 3 do
		lu.assertEquals(opens(player, "talk " .. i), "transfer", "talk " .. i)
	end

	lu.assertEquals(opens(N.pilot({ met = true, t4 = ALL, paid = ALL, pilotTier = 4 }), "pilot tier 4"), "transfer", "at pilot tier 4 (the screen raises it)")
end

-- G19
-- AC-7, AC-11
function TestSmugglerT4Gates:test_a_pilot_with_the_master_skill_opens_here_for_work()
	lu.assertEquals(opens(N.pilot({ met = true, t4 = ALL, paid = ALL, master = true }), "master"), "here_for_work", "master")
	lu.assertEquals(opens(N.pilot({ met = true, t4 = ALL, paid = ALL, master = true }), "master again"), "here_for_work", "every talk")
end

-- AC-7: every gate screen is in the template
function TestSmugglerT4Gates:test_every_gate_screen_is_in_the_template()
	local ids = {}

	for _, s in ipairs(H.conversationTemplateTable(N.TEMPLATE).screens) do
		ids[s.id] = true
	end

	for _, id in ipairs({ "not_neutral", "off_track", "not_ready", "busy", "m1_failed", "m2_failed", "m3_failed", "m4_failed", "m1_reward", "m2_reward", "m3_reward", "m4_reward",
		"ready", "ready_train", "intro", "tier4_incomplete", "transfer", "here_for_work" }) do
		lu.assertTrue(ids[id] == true, "gate screen " .. id .. " is in " .. N.TEMPLATE)
	end
end

-- AC-7: the refusals walk to their ends and change nothing
function TestSmugglerT4Gates:test_the_refusal_dialogues_end_and_change_nothing()
	local cases = {
		{ player = N.pilot({ pilot = false, squadron = false }), ids = { "not_neutral" } },
		{ player = N.pilot({ squadron = CORSEC_SQUADRON, t3 = { 1 } }), choices = { "s_c1ff5062" }, ids = { "off_track", "off_track_refused" } },
		{ player = N.pilot({ t3 = {} }), choices = { "s_e86f1062" }, ids = { "not_ready", "not_ready_know" } },
		{ player = N.pilot({ t3 = {} }), choices = { "s_5206ea9b" }, ids = { "not_ready", "not_ready_business" } },
	}

	for i, c in ipairs(cases) do
		local before = N.snapshot(c.player)
		local t = N.talk(c.player, c.choices)

		lu.assertEquals(N.ids(t), c.ids, "case " .. i .. ": screens")
		lu.assertTrue(t[#t].stop, "case " .. i .. ": the last screen ends the conversation")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "case " .. i .. ": client strings")
		lu.assertEquals(N.snapshot(c.player), before, "case " .. i .. ": changes nothing")
	end
end

---------------------------------------------------------------------------------------------
-- The helpers (Content contract 3) the tests and the walks rely on
---------------------------------------------------------------------------------------------

TestSmugglerT4Helpers = {}

function TestSmugglerT4Helpers:setUp()
	H.reset()
	N.requireConversation(lu)
end

-- isWon: the chain end is complete
function TestSmugglerT4Helpers:test_isWon_is_true_when_the_chain_end_is_complete()
	for n, m in ipairs(N.MISSIONS) do
		local p = N.pilot()

		lu.assertFalse(handler():isWon(p, n), "mission " .. n .. ": nothing done")
		N.setState(p, m.chain[1], "complete")
		lu.assertFalse(handler():isWon(p, n), "mission " .. n .. ": the head alone complete")
		N.setState(p, m.won[#m.won], "complete")
		lu.assertTrue(handler():isWon(p, n), "mission " .. n .. ": the end complete")
	end

	-- M3: recovery 3c is the end; the surprise attack child alone is not
	local p = N.pilot()

	N.setState(p, G[8], "complete")
	lu.assertFalse(handler():isWon(p, 3), "3c_sa complete alone is not a won mission 3")
end

-- isActive follows the whole chain
function TestSmugglerT4Helpers:test_isActive_follows_the_whole_chain_including_the_failure_child()
	for n, m in ipairs(N.MISSIONS) do
		for i, g in ipairs(m.chain) do
			local p = N.pilot()

			N.setState(p, g, "active")
			lu.assertTrue(handler():isActive(p, n), "mission " .. n .. ": member " .. i .. " (" .. g .. ") active")
		end

		lu.assertFalse(handler():isActive(N.pilot(), n), "mission " .. n .. ": nothing active")
	end
end

-- isFailed: attempted, not won, not active
function TestSmugglerT4Helpers:test_isFailed_isPaid_and_hasStatus()
	local p = N.pilot()

	lu.assertFalse(handler():isFailed(p, 1), "never attempted")
	N.setMission(p, 1, "attempted")
	lu.assertTrue(handler():isFailed(p, 1), "attempted")
	N.setMission(p, 1, "active")
	lu.assertFalse(handler():isFailed(p, 1), "attempted and active")
	N.setMission(p, 1, "won")
	lu.assertFalse(handler():isFailed(p, 1), "attempted and won")
	lu.assertTrue(handler():hasStatus(p, 1, ":attempted"), "hasStatus :attempted")
	lu.assertFalse(handler():hasStatus(p, 1, ":reward"), "hasStatus :reward before the payment")
	lu.assertFalse(handler():isPaid(p, 1), "isPaid before the payment")
	N.setMission(p, 1, "paid")
	lu.assertTrue(handler():hasStatus(p, 1, ":reward"), "hasStatus :reward after the payment")
	lu.assertTrue(handler():isPaid(p, 1), "isPaid after the payment")
	lu.assertEquals(handler():getQuestString(3), { type = "inspect", name = "tatooine_privateer_tier4_3a" }, "getQuestString(3)")
end

-- hasKey / setKey
function TestSmugglerT4Helpers:test_hasKey_and_setKey_use_the_player_id_and_the_value_1()
	local p = N.pilot()

	lu.assertFalse(handler():hasKey(p, SmugglerSquadronScreenplay.TIER4_MET_KEY), "no key")
	handler():setKey(p, SmugglerSquadronScreenplay.TIER4_MET_KEY)
	lu.assertTrue(handler():hasKey(p, SmugglerSquadronScreenplay.TIER4_MET_KEY), "key set")
	lu.assertEquals(H.getQuestStatus(p, N.MET_SUFFIX), "1", "<playerID>SmugglerSquadronScreenplay:metTier4 == 1")
end

-- isOnMission: the four chains and the four duties
function TestSmugglerT4Helpers:test_isOnMission_is_true_for_any_chain_or_duty()
	lu.assertFalse(handler():isOnMission(N.pilot()), "nothing running")

	for n = 1, 4 do
		local p = N.pilot()

		N.setMission(p, n, "active")
		lu.assertTrue(handler():isOnMission(p), "mission " .. n .. " running")
	end

	for _, duty in ipairs(N.DUTIES) do
		lu.assertTrue(handler():isOnMission(N.pilot({ duty4 = duty })), duty .. " running")
	end
end

-- getNextMission: the smallest mission not won
function TestSmugglerT4Helpers:test_getNextMission_is_the_first_mission_not_won()
	lu.assertEquals(handler():getNextMission(N.pilot()), 1, "nothing won")
	lu.assertEquals(handler():getNextMission(N.pilot({ mission = { [1] = "won" } })), 2, "mission 1 won")
	lu.assertEquals(handler():getNextMission(N.pilot({ mission = { [1] = "failed", [2] = "won" } })), 1, "mission 1 failed, 2 won")
	lu.assertEquals(handler():getNextMission(N.pilot({ paid = { 1, 2, 3 } })), 4, "three won")
	lu.assertNil(handler():getNextMission(N.pilot({ paid = ALL })), "all four won")
end

-- getReadyMission (FN-2)
function TestSmugglerT4Helpers:test_getReadyMission_needs_as_many_skills_as_the_next_mission_number_and_no_attempt()
	lu.assertNil(handler():getReadyMission(N.pilot()), "no skill")
	lu.assertEquals(handler():getReadyMission(N.pilot({ t4 = { 3 } })), 1, "one skill (any of the four)")
	lu.assertNil(handler():getReadyMission(N.pilot({ t4 = { 1 }, paid = { 1 } })), "one skill, mission 2 next")
	lu.assertEquals(handler():getReadyMission(N.pilot({ t4 = { 2, 4 }, paid = { 1 } })), 2, "two skills, mission 2 next")
	lu.assertNil(handler():getReadyMission(N.pilot({ t4 = { 1 }, mission = { [1] = "attempted" } })), "mission 1 attempted")
	lu.assertEquals(handler():getReadyMission(N.pilot({ t4 = ALL, paid = { 1, 2, 3 } })), 4, "four skills, mission 4 next")
	lu.assertNil(handler():getReadyMission(N.pilot({ t4 = ALL, paid = ALL })), "all won")
end

-- isReadyForTraining (J:72-79)
function TestSmugglerT4Helpers:test_isReadyForTraining_needs_tier_3_xp_no_tier_4_and_no_ready_mission()
	lu.assertTrue(handler():isReadyForTraining(N.pilot({ xp = XP })), "the plain case")
	lu.assertFalse(handler():isReadyForTraining(N.pilot({ xp = XP - 1 })), "one XP short")
	lu.assertFalse(handler():isReadyForTraining(N.pilot({ xp = XP, t3 = { 1, 2, 3 } })), "three _03 skills")
	lu.assertFalse(handler():isReadyForTraining(N.pilot({ xp = XP, t4 = { 1 } })), "a ready mission")
	lu.assertTrue(handler():isReadyForTraining(N.pilot({ xp = XP, t4 = { 1 }, paid = { 1 } })), "the next mission is not ready")
	lu.assertFalse(handler():isReadyForTraining(N.pilot({ xp = XP, t4 = ALL, paid = ALL })), "tier 4 done")
end

-- canFlyNonTrackDuty (J:183-190, SS D-6, D-21)
function TestSmugglerT4Helpers:test_canFlyNonTrackDuty_needs_a_neutral_pilot_with_the_tier_3_skills_and_no_quest()
	lu.assertTrue(handler():canFlyNonTrackDuty(N.pilot({ squadron = CORSEC_SQUADRON })), "a CorSec pilot with the four _03 skills")
	lu.assertTrue(handler():canFlyNonTrackDuty(N.pilot({ squadron = false })), "a squadron-less pilot")
	lu.assertFalse(handler():canFlyNonTrackDuty(N.pilot({ squadron = CORSEC_SQUADRON, t3 = { 1, 2, 3 } })), "three _03 skills")
	lu.assertFalse(handler():canFlyNonTrackDuty(N.pilot({ squadron = CORSEC_SQUADRON, datapad = "story" })), "a datapad quest")
	lu.assertFalse(handler():canFlyNonTrackDuty(N.pilot({ squadron = CORSEC_SQUADRON, datapad = "duty" })), "a datapad duty")
	lu.assertFalse(handler():canFlyNonTrackDuty(N.pilot({ squadron = CORSEC_SQUADRON, duty4 = G[13] })), "a Nirame duty running")
	lu.assertFalse(handler():canFlyNonTrackDuty(N.pilot({ pilot = "rebel", squadron = false })), "a Rebel pilot")
end

-- raisePilotTier (D-10)
function TestSmugglerT4Helpers:test_raisePilotTier_goes_3_to_4_and_4_to_5_and_never_lowers_or_skips()
	local p = N.pilot({ pilotTier = 3 })

	handler():raisePilotTier(p, LuaPlayerObject(CreatureObject(p):getPlayerObject()))
	lu.assertEquals(p.ghost.pilotTier, 4, "3 -> 4 with the four _03 skills")

	handler():raisePilotTier(p, LuaPlayerObject(CreatureObject(p):getPlayerObject()))
	lu.assertEquals(p.ghost.pilotTier, 4, "4 stays 4 without the _04 skills")

	p = N.pilot({ pilotTier = 4, t4 = ALL })
	handler():raisePilotTier(p, LuaPlayerObject(CreatureObject(p):getPlayerObject()))
	lu.assertEquals(p.ghost.pilotTier, 5, "4 -> 5 with the four _04 skills")
	handler():raisePilotTier(p, LuaPlayerObject(CreatureObject(p):getPlayerObject()))
	lu.assertEquals(p.ghost.pilotTier, 5, "5 stays 5")

	p = N.pilot({ pilotTier = 3, t4 = ALL })
	handler():raisePilotTier(p, LuaPlayerObject(CreatureObject(p):getPlayerObject()))
	lu.assertEquals(p.ghost.pilotTier, 5, "3 -> 4 -> 5 in one call when both tiers are complete")

	p = N.pilot({ pilotTier = 2 })
	handler():raisePilotTier(p, LuaPlayerObject(CreatureObject(p):getPlayerObject()))
	lu.assertEquals(p.ghost.pilotTier, 2, "tier 2 is not skipped")

	p = N.pilot({ pilotTier = 3, t3 = { 1, 2, 3 } })
	handler():raisePilotTier(p, LuaPlayerObject(CreatureObject(p):getPlayerObject()))
	lu.assertEquals(p.ghost.pilotTier, 3, "3 stays 3 without the fourth _03 skill")
	lu.assertNil(handler():raisePilotTier(p, nil), "a nil ghost returns")
end

---------------------------------------------------------------------------------------------
-- AC-8: the first meeting, the duty menu and the off-track menu
---------------------------------------------------------------------------------------------

TestSmugglerT4Duties = {}

function TestSmugglerT4Duties:setUp()
	H.reset()
	N.requireConversation(lu)
	self.spies = N.spyStarts()
end

local INTRO_WALK = { "s_6b1ef548", "s_b0328fe7", "s_f1aeca8b", "s_879f33d", "s_67e6df55", "s_fc00cf40", "s_5866c569" }
local INTRO_IDS = { "intro", "intro_busy", "intro_name", "intro_love", "intro_roster", "duty_escort_info", "duty_freighter_info", "duty_menu" }

-- AC-8, D-8: the first meeting walks to the duty menu; the met key is set on display of intro_busy
function TestSmugglerT4Duties:test_the_first_meeting_walks_to_the_duty_menu_and_sets_the_met_key_on_intro_busy()
	local player = N.pilot()
	local t = N.talk(player, INTRO_WALK)

	lu.assertEquals(N.ids(t), INTRO_IDS, "the first-meeting walk")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(t[1].text, N.PREFIX .. "s_593a67cd", "intro is the pre-NGE line in slot s_350")
	lu.assertEquals(H.getQuestStatus(player, N.MET_SUFFIX), "1", "the met key is set")
	lu.assertEquals(N.started(self.spies), {}, "no quest starts on the way")

	local before = N.talk(N.pilot(), { "s_6b1ef548" })

	lu.assertEquals(N.ids(before), { "intro", "intro_busy" }, "the met key is set when intro_busy is shown, before the next reply")

	local p2 = N.pilot()

	N.talk(p2)
	lu.assertNil(H.getQuestStatus(p2, N.MET_SUFFIX), "showing intro alone does not set the key")
end

-- AC-8: the next talk does not open intro again
function TestSmugglerT4Duties:test_after_intro_busy_the_next_talk_opens_tier4_incomplete()
	local player = N.pilot()

	N.talk(player, { "s_6b1ef548" })
	lu.assertEquals(N.firstScreen(player), "tier4_incomplete", "the next talk")
	lu.assertEquals(N.firstScreen(player), "tier4_incomplete", "and the one after")
end

-- AC-8: on the three duty menus each duty reply starts exactly its duty once
function TestSmugglerT4Duties:test_each_duty_reply_on_the_three_menus_starts_exactly_its_duty_once()
	local pilots = {
		duty_menu = function() return N.pilot() end,
		tier4_incomplete = function() return N.pilot({ met = true }) end,
		here_for_work = function() return N.pilot({ met = true, t4 = ALL, paid = ALL, master = true }) end,
	}

	for _, menu in ipairs(N.DUTY_MENUS) do
		for _, reply in ipairs(N.DUTY_REPLIES) do
			if reply.screen ~= "duty_explain" then
				H.reset()

				local spies = N.spyStarts()
				local player = pilots[menu]()
				local t

				if menu == "duty_menu" then
					t = N.drive(player, "duty_menu", { reply.sid })
				else
					t = N.talk(player, { reply.sid })
				end

				lu.assertEquals(N.ids(t), { menu, reply.screen }, menu .. " -> " .. reply.sid)
				lu.assertTrue(t[#t].stop, menu .. " -> " .. reply.screen .. " ends the conversation")
				lu.assertEquals(N.started(spies), { N.DUTY_SCREENS[reply.screen] }, menu .. " -> " .. reply.screen .. ": the duties started")
				lu.assertEquals(CS.transcriptUnresolved(t), {}, menu .. " -> " .. reply.screen .. ": client strings")
				lu.assertEquals(spies[N.DUTY_SCREENS[reply.screen]][1].args[1], player, "the duty gets the pilot")
			end
		end
	end
end

-- AC-8: showing a menu starts nothing
function TestSmugglerT4Duties:test_showing_a_duty_menu_starts_nothing()
	N.talk(N.pilot({ met = true }))
	N.talk(N.pilot({ met = true, t4 = ALL, paid = ALL, master = true }))
	N.drive(N.pilot(), "duty_menu")
	lu.assertEquals(N.started(self.spies), {}, "duties started by showing the menus")
end

-- AC-8: "Could you explain it to me again?." returns to duty_explain -> duty_escort_info and the loop leads back to the menu
function TestSmugglerT4Duties:test_explain_again_loops_through_duty_explain_back_to_the_menu()
	for _, menu in ipairs(N.DUTY_MENUS) do
		local player = menu == "duty_menu" and N.pilot() or (menu == "tier4_incomplete" and N.pilot({ met = true }) or N.pilot({ met = true, t4 = ALL, paid = ALL, master = true }))
		local t

		if menu == "duty_menu" then
			t = N.drive(player, "duty_menu", { "s_694ce3f1", "s_67e6df55", "s_fc00cf40", "s_5866c569" })
			lu.assertEquals(N.ids(t), { "duty_menu", "duty_explain", "duty_escort_info", "duty_freighter_info", "duty_menu" }, "duty_menu loop")
		else
			t = N.talk(player, { "s_694ce3f1", "s_67e6df55", "s_fc00cf40", "s_5866c569" })
			lu.assertEquals(N.ids(t), { menu, "duty_explain", "duty_escort_info", "duty_freighter_info", "duty_menu" }, menu .. " -> explain loop")
		end

		lu.assertEquals(CS.transcriptUnresolved(t), {}, menu .. ": client strings")
	end

	lu.assertEquals(N.started(self.spies), {}, "explaining starts nothing")
end

-- AC-8: the duty screens show their lines and NPC animations; none of them changes anything but the duty
function TestSmugglerT4Duties:test_a_duty_changes_nothing_but_starting_it()
	local player = N.pilot({ met = true })
	local before = N.snapshot(player)

	N.talk(player, { "s_412dc22e" })
	lu.assertEquals(N.snapshot(player), before, "talking and choosing a duty (the duty itself is spied)")
end

-- AC-8: a duty raises the pilot tier 3 -> 4 (the safety net of D-10) and 4 -> 5 when tier 4 is complete
function TestSmugglerT4Duties:test_a_duty_screen_raises_the_pilot_tier()
	local p = N.pilot({ met = true, pilotTier = 3 })

	N.talk(p, { "s_412dc22e" })
	lu.assertEquals(p.ghost.pilotTier, 4, "3 -> 4 on a duty screen")

	p = N.pilot({ met = true, t4 = ALL, paid = ALL, master = true, pilotTier = 4 })
	N.talk(p, { "s_4bb3bd9d" })
	lu.assertEquals(p.ghost.pilotTier, 5, "4 -> 5 on a duty screen with the four _04 skills")
end

---------------------------------------------------------------------------------------------
-- AC-8: off track
---------------------------------------------------------------------------------------------

TestSmugglerT4OffTrack = {}

function TestSmugglerT4OffTrack:setUp()
	H.reset()
	N.requireConversation(lu)
	self.spies = N.spyStarts()
end

-- AC-8 (C-2): a pilot with the four _03 skills and no quest is offered the off-track duties
function TestSmugglerT4OffTrack:test_off_track_leads_to_the_duties_when_canFlyNonTrackDuty_holds()
	for _, squadron in ipairs({ CORSEC_SQUADRON, RSF_SQUADRON, false }) do
		H.reset()

		local t = N.talk(N.pilot({ squadron = squadron }), { "s_c1ff5062", "s_c82e9a2f" })

		lu.assertEquals(N.ids(t), { "off_track", "off_track_duties", "duty_explain" }, "off track, can fly a duty")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-8 (C-2): any space quest or a missing _03 skill leads to the refusal
function TestSmugglerT4OffTrack:test_off_track_leads_to_the_refusal_with_a_quest_or_without_all_four_tier_3_skills()
	local cases = {
		{ "a datapad story quest", { squadron = CORSEC_SQUADRON, datapad = "story" } },
		{ "a datapad duty", { squadron = CORSEC_SQUADRON, datapad = "duty" } },
		{ "a running Nirame duty", { squadron = CORSEC_SQUADRON, duty4 = G[14] } },
		{ "three _03 skills", { squadron = CORSEC_SQUADRON, t3 = { 1, 2, 3 } } },
		{ "no _03 skill", { squadron = RSF_SQUADRON, t3 = {} } },
	}

	for _, c in ipairs(cases) do
		H.reset()

		local t = N.talk(N.pilot(c[2]), { "s_c1ff5062" })

		lu.assertEquals(N.ids(t), { "off_track", "off_track_refused" }, c[1])
		lu.assertTrue(t[2].stop, c[1] .. ": the refusal ends the conversation")
	end
end

-- AC-8: the static link of off_track is the duties screen and the handler decides; the option text is the same line
function TestSmugglerT4OffTrack:test_the_off_track_option_text_is_the_same_whichever_way_it_leads()
	local yes = N.drive(N.pilot({ squadron = CORSEC_SQUADRON }), "off_track")
	local no = N.drive(N.pilot({ squadron = CORSEC_SQUADRON, datapad = "story" }), "off_track")

	lu.assertEquals(N.optionSids(yes[1]), { "s_c1ff5062" }, "reply (yes)")
	lu.assertEquals(N.optionSids(no[1]), { "s_c1ff5062" }, "reply (no)")
	lu.assertEquals(N.linksOf(yes[1]), { "off_track_duties" }, "link (can fly a duty)")
	lu.assertEquals(N.linksOf(no[1]), { "off_track_refused" }, "link (with a quest)")
end

-- AC-8: an off-track pilot takes a duty from the menu; the duty starts once and nothing else
function TestSmugglerT4OffTrack:test_an_off_track_pilot_can_take_a_duty_after_the_briefing()
	local t = N.talk(N.pilot({ squadron = CORSEC_SQUADRON }), { "s_c1ff5062", "s_c82e9a2f", "s_67e6df55", "s_fc00cf40", "s_5866c569", "s_aa6112c9" })

	lu.assertEquals(N.ids(t), { "off_track", "off_track_duties", "duty_explain", "duty_escort_info", "duty_freighter_info", "duty_menu", "duty_recovery" }, "the off-track walk to a duty")
	lu.assertEquals(N.started(self.spies), { G[15] }, "the recovery duty started once")
end

-- AC-8: showing off_track or the refusal starts nothing and sets no key
function TestSmugglerT4OffTrack:test_off_track_screens_start_nothing_and_set_no_key()
	local player = N.pilot({ squadron = CORSEC_SQUADRON })
	local before = N.snapshot(player)

	N.talk(player, { "s_c1ff5062" })
	N.talk(player, { "s_c1ff5062", "s_c82e9a2f" })
	lu.assertEquals(N.started(self.spies), {}, "no quest started")
	lu.assertNil(H.getQuestStatus(player, N.MET_SUFFIX), "no met key for an off-track pilot")
	lu.assertEquals(N.snapshot(player), before, "nothing changed")
end
