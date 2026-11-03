-- Beissa: which screen a pilot opens on (gate table B0 .. B18), the helpers and the pure-gate invariant I-9.
-- Spec: .claude/work/smuggler-tier3-beissa/01-spec.md (AC-6; Conversation flow 1; Content contract 3; D-7, D-9, D-17; I-9).
--
-- One test per gate row: a pilot built to satisfy that row and none above it opens on the listed screen. The builder is smuggler_tier3_data.lua B.pilot
-- (default: a Smuggler tier 2 graduate at pilot tier 3 with no tier 3 state). Every first-screen call is wrapped by `opens`, which also proves that
-- getInitialScreen changes nothing (I-9: no quest start, journal write, :attempted key, skill, credit, item or pilot tier change).

local lu = require("luaunit")
local H = require("harness")
local B = require("smuggler_tier3_data")

B.load()

local ALL = { 1, 2, 3, 4 }

local function handler() return rawget(_G, B.HANDLER) end

TestSmugglerT3Gates = {}

function TestSmugglerT3Gates:setUp()
	H.reset()
	B.requireConversation(lu)
end

-- the id of the screen getInitialScreen picks, with a proof that the call changes nothing (I-9). The screen handlers of the talk are not run (a reward
-- screen pays on display), so this is the gate alone.
local function opens(player, label)
	local before = B.snapshot(player)
	local pScreen = handler():getInitialScreen(player, B.npc(), H.conversationTemplate(B.TEMPLATE))

	lu.assertNotNil(pScreen, (label or "gate") .. ": getInitialScreen returns a screen")
	lu.assertEquals(B.snapshot(player), before, (label or "gate") .. ": getInitialScreen changes nothing (I-9)")

	return LuaConversationScreen(pScreen):getScreenID()
end

-- B0
-- AC-6
function TestSmugglerT3Gates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = B.pilot(), B.npc(), H.conversationTemplate(B.TEMPLATE)

	lu.assertNil(handler():getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(handler():getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(handler():getInitialScreen(player, npc, nil), "no template")
end

-- B1 (D-9)
-- AC-6
function TestSmugglerT3Gates:test_jtl_disabled_opens_not_neutral()
	H.Engine.config.jtlEnabled = false
	lu.assertEquals(opens(B.pilot(), "JTL disabled"), "not_neutral", "JTL disabled")
	lu.assertEquals(opens(B.pilot({ mission = { [1] = "won" } }), "JTL disabled, mission won"), "not_neutral", "JTL disabled beats every later row")
end

-- B1
-- AC-6
function TestSmugglerT3Gates:test_a_pilot_without_a_player_object_opens_not_neutral()
	local player = B.pilot()

	player.ghost = nil

	local pScreen = handler():getInitialScreen(player, B.npc(), H.conversationTemplate(B.TEMPLATE))

	lu.assertEquals(LuaConversationScreen(pScreen):getScreenID(), "not_neutral", "ghost is nil")
end

-- B2
-- AC-6
function TestSmugglerT3Gates:test_non_pilots_and_rebel_and_imperial_pilots_open_not_neutral()
	lu.assertEquals(opens(B.pilot({ pilot = false, squadron = false }), "non-pilot"), "not_neutral", "no pilot skills")
	lu.assertEquals(opens(B.pilot({ pilot = "rebel", squadron = false }), "rebel pilot"), "not_neutral", "a Rebel pilot")
	lu.assertEquals(opens(B.pilot({ pilot = "imperial", squadron = false }), "imperial pilot"), "not_neutral", "an Imperial pilot")
	lu.assertEquals(opens(B.pilot({ pilot = "rebel", faction = "rebel", squadron = false }), "rebel pilot with faction"), "not_neutral", "a Rebel pilot of the Rebel faction")
	lu.assertEquals(opens(B.pilot({ pilot = "imperial", faction = "imperial", squadron = false }), "imperial pilot with faction"), "not_neutral", "an Imperial pilot of the Imperial faction")
end

-- B3
-- AC-6
function TestSmugglerT3Gates:test_corsec_rsf_and_squadronless_neutral_pilots_open_off_track()
	lu.assertEquals(opens(B.pilot({ squadron = CORSEC_SQUADRON }), "CorSec"), "off_track", "a CorSec pilot")
	lu.assertEquals(opens(B.pilot({ squadron = RSF_SQUADRON }), "RSF"), "off_track", "an RSF pilot")
	lu.assertEquals(opens(B.pilot({ squadron = false }), "squadron-less"), "off_track", "a neutral pilot without a squadron")
	lu.assertEquals(opens(B.pilot({ squadron = CORSEC_SQUADRON, mission = { [1] = "won" } }), "CorSec with Smuggler state"), "off_track", "off-track beats the not-ready and mission rows")
end

-- B4
-- AC-6
function TestSmugglerT3Gates:test_a_smuggler_without_the_tier_2_series_opens_not_ready()
	lu.assertEquals(opens(B.pilot({ t2 = false }), "no tier 2"), "not_ready", "a Smuggler with nothing of tier 2")

	for n = 1, 4 do
		for _, state in ipairs({ "fresh", "attempted", "active" }) do
			H.reset()
			lu.assertEquals(opens(B.pilot({ missions2 = { [n] = state } }), "tier 2 mission " .. n .. " " .. state), "not_ready", "four _02 skills, tier 2 mission " .. n .. " " .. state)
		end
	end

	for i = 1, 4 do
		H.reset()

		local p = B.pilot({ t2 = 4 })

		p.skills[B.TIER2_SKILLS[i]] = nil
		lu.assertEquals(opens(p, "_02 skill " .. i .. " missing"), "not_ready", "four tier 2 missions won, the _02 skill " .. i .. " missing")
	end

	H.reset()
	lu.assertEquals(opens(B.pilot({ t2 = 3 }), "three _02 skills"), "not_ready", "three _02 skills, four missions won")
end

-- B4: the series is skills plus won (paid or not) missions; the pilot tier is not read
-- AC-6
function TestSmugglerT3Gates:test_the_tier_2_series_needs_won_missions_not_paid_ones_and_ignores_the_pilot_tier()
	lu.assertEquals(opens(B.pilot({ missions2 = { [1] = "won", [2] = "won", [3] = "won", [4] = "won" } }), "tier 2 missions won, unpaid"), "m1_offer", "won and unpaid is enough")

	for _, tier in ipairs({ 2, 3 }) do
		H.reset()
		lu.assertEquals(opens(B.pilot({ pilotTier = tier }), "pilot tier " .. tier), "m1_offer", "pilot tier " .. tier)
	end
end

-- B5 (D-17)
-- AC-6
function TestSmugglerT3Gates:test_a_running_mission_or_any_datapad_space_quest_opens_busy()
	for n = 1, 4 do
		H.reset()
		lu.assertEquals(opens(B.pilot({ mission = { [n] = "active" } }), "mission " .. n .. " running"), "busy", "mission " .. n .. " running (head active)")
	end

	-- a split child alone is active (the head already completed)
	for n, m in ipairs(B.MISSIONS) do
		H.reset()

		local player = B.pilot({ mission = { [n] = "attempted" } })

		B.setState(player, m.chain[#m.chain], "active")
		lu.assertEquals(opens(player, "chain end active"), "busy", "mission " .. n .. ": only the chain end is active")
	end

	lu.assertEquals(opens(B.pilot({ datapad = "story" }), "story in datapad"), "busy", "a story mission in the datapad")
	lu.assertEquals(opens(B.pilot({ datapad = "duty" }), "duty in datapad"), "busy", "a duty in the datapad (another trainer's)")
end

-- B5 above B6 .. B17
-- AC-6
function TestSmugglerT3Gates:test_busy_comes_before_failures_rewards_and_offers()
	lu.assertEquals(opens(B.pilot({ mission = { [1] = "won", [2] = "active" } })), "busy", "mission 1 won and unpaid, mission 2 running")
	lu.assertEquals(opens(B.pilot({ t3 = { 1 }, paid = { 1 }, mission = { [2] = "failed", [3] = "active" } })), "busy", "mission 2 failed, mission 3 running")
	lu.assertEquals(opens(B.pilot({ datapad = "story", mission = { [1] = "failed" } })), "busy", "mission 1 failed, a datapad quest")
	lu.assertEquals(opens(B.pilot({ datapad = "duty", mission = { [1] = "won" } })), "busy", "mission 1 won, a duty in the datapad")
	lu.assertEquals(opens(B.pilot({ t3 = ALL, paid = ALL, datapad = "story" })), "busy", "everything done, a datapad quest")
end

-- B5: the busy line has two replies, both end the conversation
-- AC-6
function TestSmugglerT3Gates:test_busy_walks_to_its_endings_and_grants_nothing()
	local player = B.pilot({ mission = { [2] = "active" } })
	local before = B.snapshot(player)

	local t = B.talk(player, { "s_11a6885c" })

	lu.assertEquals(B.ids(t), { "busy", "busy_finish" }, "busy -> You, actually.")
	lu.assertTrue(t[2].stop, "busy_finish ends")

	t = B.talk(player, { "s_5288ea5c", "s_ac7fe93" })
	lu.assertEquals(B.ids(t), { "busy", "busy_why", "busy_back_to_work" }, "busy -> why -> back to work")
	lu.assertTrue(t[3].stop, "busy_back_to_work ends")
	lu.assertEquals(B.snapshot(player), before, "the busy dialogue changes nothing")
end

-- B6 .. B9: failed (attempted, not won, not running) and aborted look the same
-- AC-6
function TestSmugglerT3Gates:test_a_failed_or_aborted_mission_opens_its_failed_screen()
	for n = 1, 4 do
		local paid, t3 = {}, {}

		for i = 1, n - 1 do
			paid[i] = i
			t3[i] = i
		end

		for _, state in ipairs({ "attempted", "partial" }) do
			H.reset()
			lu.assertEquals(opens(B.pilot({ t3 = t3, paid = paid, mission = { [n] = state } }), "mission " .. n .. " " .. state), "m" .. n .. "_failed", "mission " .. n .. " " .. state)
		end

		-- aborted: it was running, then the journal entry went away
		H.reset()

		local player = B.pilot({ t3 = t3, paid = paid, mission = { [n] = "active" } })

		B.setState(player, B.MISSIONS[n].head, "none")
		lu.assertEquals(opens(player, "mission " .. n .. " aborted"), "m" .. n .. "_failed", "mission " .. n .. " aborted")
	end
end

-- B6 .. B9: the lowest failed mission first; failed beats reward and offer
-- AC-6
function TestSmugglerT3Gates:test_a_failed_mission_comes_before_a_reward_and_the_lowest_failed_one_first()
	lu.assertEquals(opens(B.pilot({ mission = { [1] = "failed", [2] = "won" } })), "m1_failed", "mission 1 failed, mission 2 won")
	lu.assertEquals(opens(B.pilot({ mission = { [2] = "failed", [3] = "failed" }, t3 = { 1 }, paid = { 1 } })), "m2_failed", "missions 2 and 3 failed")
	lu.assertEquals(opens(B.pilot({ mission = { [1] = "won", [4] = "failed" } })), "m4_failed", "mission 1 won and unpaid, mission 4 failed: failed first")
	lu.assertEquals(opens(B.pilot({ mission = { [1] = "failed", [2] = "failed" } })), "m1_failed", "missions 1 and 2 failed")
end

-- B10 .. B13
-- AC-6
function TestSmugglerT3Gates:test_a_won_mission_with_fewer_than_n_skills_opens_its_reward_screen()
	for n = 1, 4 do
		local have, paid = {}, {}

		for i = 1, n - 1 do
			have[i] = i
			paid[i] = i
		end

		H.reset()
		lu.assertEquals(opens(B.pilot({ t3 = have, paid = paid, mission = { [n] = "won" } }), "mission " .. n .. " won"), "m" .. n .. "_reward", "mission " .. n .. " won, " .. (n - 1) .. " skills")
	end
end

-- B10 .. B13: the smallest mission whose skill is not chosen yet comes first
-- AC-6
function TestSmugglerT3Gates:test_the_smallest_unrewarded_won_mission_comes_first()
	lu.assertEquals(opens(B.pilot({ mission = { [1] = "won", [2] = "won" } })), "m1_reward", "missions 1 and 2 won, no skill")
	lu.assertEquals(opens(B.pilot({ t3 = { 2 }, paid = { 1 }, mission = { [2] = "won" } })), "m2_reward", "mission 1 skill chosen, mission 2 won")
	lu.assertEquals(opens(B.pilot({ t3 = { 3, 1 }, paid = { 1, 2 }, mission = { [3] = "won", [4] = "won" } })), "m3_reward", "two skills, missions 3 and 4 won")
end

-- B10 .. B17: a mission whose skill was chosen shows no reward screen and the next offer follows
-- AC-6, AC-7
function TestSmugglerT3Gates:test_a_mission_with_its_skill_chosen_shows_no_reward_screen_and_the_next_offer_follows()
	for n = 1, 3 do
		local have, paid = {}, {}

		for i = 1, n do
			have[i] = i
			paid[i] = i
		end

		H.reset()
		lu.assertEquals(opens(B.pilot({ t3 = have, paid = paid }), "missions 1.." .. n .. " done"), "m" .. (n + 1) .. "_offer", "missions 1.." .. n .. " won, skills chosen")
	end
end

-- B13 (D-7)
-- AC-6, AC-10
function TestSmugglerT3Gates:test_mission_4_won_and_unpaid_opens_m4_reward_even_with_four_skills()
	lu.assertEquals(opens(B.pilot({ t3 = ALL, paid = { 1, 2, 3 }, mission = { [4] = "won" } })), "m4_reward", "mission 4 won, unpaid, four skills")
	lu.assertEquals(opens(B.pilot({ t3 = { 1, 2, 3 }, paid = { 1, 2, 3 }, mission = { [4] = "won" } })), "m4_reward", "mission 4 won, three skills")
	lu.assertEquals(opens(B.pilot({ t3 = ALL, paid = ALL })), "tier_done", "mission 4 paid, four skills: the hand-off")
end

-- B14 .. B17
-- AC-6
function TestSmugglerT3Gates:test_the_first_mission_not_won_is_offered()
	lu.assertEquals(opens(B.pilot()), "m1_offer", "nothing done")

	local have, paid = {}, {}

	for n = 1, 4 do
		H.reset()
		lu.assertEquals(opens(B.pilot({ t3 = have, paid = paid }), "missions 1.." .. (n - 1) .. " done"), "m" .. n .. "_offer", "mission " .. n .. " is the first not won")
		have[n], paid[n] = n, n
	end
end

-- B14: a chain whose end alone is complete (no :attempted) is won as far as the gates go
-- AC-6
function TestSmugglerT3Gates:test_a_mission_won_by_its_chain_end_alone_is_not_offered_again()
	lu.assertEquals(opens(B.pilot({ mission = { [1] = "endonly" } })), "m1_reward", "only the end of mission 1 complete: won, the reward is waiting")
end

-- B18
-- AC-6, AC-10
function TestSmugglerT3Gates:test_all_four_missions_won_four_skills_and_mission_4_paid_open_tier_done()
	lu.assertEquals(opens(B.pilot({ t3 = ALL, paid = ALL })), "tier_done", "everything done")
	lu.assertEquals(opens(B.pilot({ t3 = ALL, paid = ALL, pilotTier = 4 })), "tier_done", "everything done at pilot tier 4")
end

-- AC-6: every gate screen is in the template
function TestSmugglerT3Gates:test_every_gate_screen_is_in_the_template()
	local template = H.conversationTemplateTable(B.TEMPLATE)
	local ids = {}

	for _, s in ipairs(template.screens) do
		ids[s.id] = true
	end

	for _, id in ipairs({ "not_neutral", "off_track", "not_ready", "busy", "m1_failed", "m2_failed", "m3_failed", "m4_failed", "m1_reward", "m2_reward", "m3_reward", "m4_reward",
		"m1_offer", "m2_offer", "m3_offer", "m4_offer", "tier_done" }) do
		lu.assertTrue(ids[id] == true, "gate screen " .. id .. " is in " .. B.TEMPLATE)
	end
end

-- AC-6: the refusals walk to their ends and grant nothing
function TestSmugglerT3Gates:test_the_refusal_dialogues_end_and_change_nothing()
	local cases = {
		{ player = B.pilot({ pilot = false, squadron = false }), ids = { "not_neutral" } },
		{ player = B.pilot({ squadron = CORSEC_SQUADRON }), choices = { "s_615d980b" }, ids = { "off_track", "off_track_refused" } },
		{ player = B.pilot({ t2 = false }), choices = { "s_4c695dbd" }, ids = { "not_ready", "not_ready_scram" } },
		{ player = B.pilot({ t2 = false }), choices = { "s_db3d67b" }, ids = { "not_ready", "not_ready_other_boss" } },
	}

	for i, c in ipairs(cases) do
		local before = B.snapshot(c.player)
		local t = B.talk(c.player, c.choices)

		lu.assertEquals(B.ids(t), c.ids, "case " .. i .. ": screens")
		lu.assertTrue(t[#t].stop, "case " .. i .. ": the last screen ends the conversation")
		lu.assertEquals(B.snapshot(c.player), before, "case " .. i .. ": changes nothing")
	end
end

---------------------------------------------------------------------------------------------
-- The helpers (Content contract 3) the tests and the walks rely on
---------------------------------------------------------------------------------------------

TestSmugglerT3Helpers = {}

function TestSmugglerT3Helpers:setUp()
	H.reset()
	B.requireConversation(lu)
end

-- isWon: the chain end is complete
function TestSmugglerT3Helpers:test_isWon_is_true_when_the_chain_end_is_complete()
	for n, m in ipairs(B.MISSIONS) do
		local p = B.pilot()

		lu.assertFalse(handler():isWon(p, n), "mission " .. n .. ": nothing done")
		B.setState(p, m.chain[1], "complete")
		lu.assertFalse(handler():isWon(p, n), "mission " .. n .. ": the head alone complete")
		B.setState(p, m.chain[#m.chain], "complete")
		lu.assertTrue(handler():isWon(p, n), "mission " .. n .. ": the end complete")
	end
end

-- isActive follows the whole chain
function TestSmugglerT3Helpers:test_isActive_follows_the_whole_chain()
	for n, m in ipairs(B.MISSIONS) do
		for i, g in ipairs(m.chain) do
			local p = B.pilot()

			B.setState(p, g, "active")
			lu.assertTrue(handler():isActive(p, n), "mission " .. n .. ": member " .. i .. " (" .. g .. ") active")
		end

		lu.assertFalse(handler():isActive(B.pilot(), n), "mission " .. n .. ": nothing active")
	end
end

-- isFailed: attempted, not won, not active
function TestSmugglerT3Helpers:test_isFailed_is_attempted_not_won_and_not_active()
	local p = B.pilot()

	lu.assertFalse(handler():isFailed(p, 1), "never attempted")
	B.setMission(p, 1, "attempted")
	lu.assertTrue(handler():isFailed(p, 1), "attempted")
	B.setMission(p, 1, "active")
	lu.assertFalse(handler():isFailed(p, 1), "attempted and active")
	B.setMission(p, 1, "won")
	lu.assertFalse(handler():isFailed(p, 1), "attempted and won")
	lu.assertTrue(handler():hasStatus(p, 1, ":attempted"), "hasStatus :attempted")
	lu.assertFalse(handler():hasStatus(p, 1, ":reward"), "hasStatus :reward before the payment")
	B.setMission(p, 1, "paid")
	lu.assertTrue(handler():hasStatus(p, 1, ":reward"), "hasStatus :reward after the payment")
end

-- isOnMission: any of the four chains
function TestSmugglerT3Helpers:test_isOnMission_is_true_for_any_of_the_four_chains()
	lu.assertFalse(handler():isOnMission(B.pilot()), "nothing running")

	for n = 1, 4 do
		local p = B.pilot()

		B.setMission(p, n, "active")
		lu.assertTrue(handler():isOnMission(p), "mission " .. n .. " running")
	end
end

-- getRewardMission: the smallest mission won whose skill count says the skill is still to be chosen (or mission 4 unpaid)
function TestSmugglerT3Helpers:test_getRewardMission_returns_the_smallest_won_mission_with_fewer_than_n_skills()
	lu.assertEquals(handler():getRewardMission(B.pilot({ mission = { [1] = "won" } })), 1, "mission 1 won, no skill")
	lu.assertEquals(handler():getRewardMission(B.pilot({ mission = { [1] = "won", [2] = "won" } })), 1, "missions 1 and 2 won, no skill")
	lu.assertEquals(handler():getRewardMission(B.pilot({ t3 = { 1 }, paid = { 1 }, mission = { [2] = "won" } })), 2, "mission 2 won, one skill")
	lu.assertEquals(handler():getRewardMission(B.pilot({ t3 = { 4, 2, 3 }, paid = { 1, 2, 3 }, mission = { [4] = "won" } })), 4, "mission 4 won, three skills")
	lu.assertEquals(handler():getRewardMission(B.pilot({ t3 = ALL, paid = { 1, 2, 3 }, mission = { [4] = "won" } })), 4, "mission 4 won and unpaid with four skills (D-7)")
end

function TestSmugglerT3Helpers:test_getRewardMission_is_nil_when_nothing_is_waiting()
	lu.assertNil(handler():getRewardMission(B.pilot()), "nothing won")
	lu.assertNil(handler():getRewardMission(B.pilot({ t3 = { 1 }, paid = { 1 } })), "mission 1 won, skill chosen")
	lu.assertNil(handler():getRewardMission(B.pilot({ t3 = ALL, paid = ALL })), "everything done")
	lu.assertNil(handler():getRewardMission(B.pilot({ mission = { [1] = "failed" } })), "mission 1 failed")
	lu.assertNil(handler():getRewardMission(B.pilot({ mission = { [1] = "active" } })), "mission 1 running")
end
