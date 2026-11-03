-- Karrde: which screen a pilot opens on (gate table K), the helpers and the pure-gate invariant I-9.
-- Spec: .claude/work/smuggler-transition-karrde/01-spec.md (AC-6, AC-9; Conversation flow 1; Content contract 3; FK-4; D-4, D-5, D-6, D-7; I-9).
--
-- One test per gate row: a pilot built to satisfy that row and none above it opens on the listed screen. The builder is
-- smuggler_transition_data.lua T.pilot (a Smuggler with all four tier 1 skills unless told otherwise; trans = the transition state; rewarded = the
-- :reward key Shamdon will write). The row K9 is deferred (tier 4) and has no test; K3 (tier 2 series done) is tested by test_smuggler_tier2_karrde.lua (smuggler-tier2-shamdon) and K2 (tier 3 done) by test_smuggler_tier3_karrde.lua (smuggler-tier3-beissa).

local lu = require("luaunit")
local H = require("harness")
local T = require("smuggler_transition_data")
local S = require("smuggler_tier1_data")
local CS = require("harness.client_strings")
local MS = require("migration_scenario")

T.load()

TestSmugglerTransGates = {}

function TestSmugglerTransGates:setUp()
	H.reset()
	T.requireConversation(lu)
end

local function opens(player) return T.firstScreen(player) end

-- K0
-- AC-6
function TestSmugglerTransGates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = T.pilot(), T.npc(), H.conversationTemplate(T.TEMPLATE)

	lu.assertNil(T.handler():getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(T.handler():getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(T.handler():getInitialScreen(player, npc, nil), "no template")
end

-- K1
-- AC-6, D-6
function TestSmugglerTransGates:test_jtl_disabled_opens_not_member_even_for_a_smuggler()
	H.Engine.config.jtlEnabled = false

	lu.assertEquals(opens(T.pilot()), "not_member", "Smuggler, JTL disabled")
	lu.assertEquals(opens(T.pilot({ trans = "won" })), "not_member", "Smuggler with a won chain, JTL disabled")
end

-- AC-6
function TestSmugglerTransGates:test_a_pilot_without_a_player_object_opens_not_member()
	local player = T.pilot()

	player.ghost = nil
	lu.assertEquals(opens(player), "not_member", "ghost is nil")
end

-- AC-6: non-pilots of every GCW faction
function TestSmugglerTransGates:test_non_pilots_of_every_faction_open_not_member()
	for _, faction in ipairs({ "neutral", "rebel", "imperial" }) do
		lu.assertEquals(opens(T.pilot({ pilot = false, squadron = false, faction = faction, tier = 0, paid = 0 })), "not_member", "non-pilot, " .. faction .. " faction")
	end
end

-- AC-6: every other squadron, and the pilots with none
function TestSmugglerTransGates:test_corsec_rsf_havoc_black_epsilon_and_squadronless_pilots_open_not_member()
	lu.assertEquals(opens(T.pilot({ squadron = CORSEC_SQUADRON })), "not_member", "CorSec pilot")
	lu.assertEquals(opens(T.pilot({ squadron = RSF_SQUADRON })), "not_member", "RSF pilot")
	lu.assertEquals(opens(T.pilot({ squadron = false })), "not_member", "neutral pilot without a squadron")
	lu.assertEquals(opens(T.pilot({ pilot = "rebel", squadron = HAVOC_SQUADRON })), "not_member", "Havoc (Rebel) pilot")
	lu.assertEquals(opens(T.pilot({ pilot = "rebel", squadron = false })), "not_member", "Rebel pilot without a squadron")
	lu.assertEquals(opens(T.pilot({ pilot = "imperial", squadron = BLACK_EPSILON_SQUADRON })), "not_member", "Black Epsilon (Imperial) pilot")
	lu.assertEquals(opens(T.pilot({ pilot = "imperial", squadron = false })), "not_member", "Imperial pilot without a squadron")
end

-- AC-6: another squadron's pilot who carries Smuggler-looking state still is not a member
function TestSmugglerTransGates:test_the_squadron_decides_not_the_state()
	lu.assertEquals(opens(T.pilot({ squadron = CORSEC_SQUADRON, trans = "won", rewarded = true })), "not_member", "CorSec pilot with a won, paid chain")
	lu.assertEquals(opens(T.pilot({ squadron = RSF_SQUADRON, trans = "active" })), "not_member", "RSF pilot with an active chain")
end

-- K4
-- AC-6: the four ways a chain is attempted and neither running nor won
function TestSmugglerTransGates:test_an_attempted_chain_that_is_not_running_and_not_won_opens_trans_failed()
	lu.assertEquals(opens(T.pilot({ trans = "attempted" })), "trans_failed", "failed or aborted: :attempted, journal empty")
	lu.assertEquals(opens(T.pilot({ trans = "patrol_only" })), "trans_failed", "patrol complete, the assassinate never started (R-2)")

	local player = T.pilot({ trans = "patrol_only" })

	T.setState(player, T.ASSASSINATE, "none")
	lu.assertEquals(opens(player), "trans_failed", "assassinate failed: its journal entry cleared")
end

-- AC-6: K4 comes before K5, as in SWG
function TestSmugglerTransGates:test_a_failed_chain_opens_trans_failed_before_the_missing_skills_are_looked_at()
	lu.assertEquals(opens(T.pilot({ trans = "attempted", tier = 2 })), "trans_failed", "failed chain, two tier 1 skills")
	lu.assertEquals(opens(T.pilot({ trans = "attempted", tier = 0 })), "trans_failed", "failed chain, no tier 1 skill")
end

-- K5
-- AC-6: 0..3 tier 1 skills
function TestSmugglerTransGates:test_a_smuggler_with_fewer_than_four_tier_1_skills_opens_dravis_employee()
	for n = 0, 3 do
		lu.assertEquals(opens(T.pilot({ tier = n, paid = 0, pilotTier = 1 })), "dravis_employee", n .. " tier 1 skills")
	end
end

-- AC-6: a surrendered pilot keeps the squadron (D-7) and loses everything else
function TestSmugglerTransGates:test_a_surrendered_smuggler_opens_dravis_employee()
	local player = T.pilot({ trans = "won", rewarded = true })

	SpaceHelpers:surrenderPilot(player)
	player.pilot = nil -- the server derives the pilot kind from the skills that are gone
	lu.assertEquals(player.ghost.squadronType, SMUGGLER_SQUADRON, "precondition: the squadron is kept (D-7)")
	lu.assertEquals(opens(player), "dravis_employee", "after the surrender")
end

-- K6
-- AC-6, D-4: won and not yet paid by Shamdon
function TestSmugglerTransGates:test_a_won_chain_that_shamdon_has_not_paid_opens_trans_won()
	lu.assertEquals(opens(T.pilot({ trans = "won" })), "trans_won", "both quests complete, no :reward key")
end

-- K7
-- AC-6
function TestSmugglerTransGates:test_a_running_chain_opens_on_trans()
	lu.assertEquals(opens(T.pilot({ trans = "active" })), "on_trans", "patrol active")
	lu.assertEquals(opens(T.pilot({ trans = "child_active" })), "on_trans", "patrol complete, assassinate active")
end

-- AC-6: either quest alone keeps the chain running
function TestSmugglerTransGates:test_the_assassinate_alone_active_without_the_attempted_key_still_opens_on_trans()
	local player = T.pilot({})

	T.setState(player, T.ASSASSINATE, "active")
	lu.assertEquals(opens(player), "on_trans", "assassinate active, no :attempted key (a run started elsewhere)")
end

-- K8
-- AC-6: tier 1 complete, never asked
function TestSmugglerTransGates:test_a_tier_1_graduate_who_was_never_asked_opens_summons()
	lu.assertEquals(opens(T.pilot({})), "summons", "four tier 1 skills, no transition state")
	lu.assertEquals(opens(T.pilot({ pilotTier = 1 })), "summons", "the pilot tier is not read (D-9)")
end

-- AC-6, D-5, FK-4: Karrde gates on his own chain only
function TestSmugglerTransGates:test_other_quests_do_not_stop_karrde_from_offering_the_transition()
	lu.assertEquals(opens(T.pilot({ datapad = "story" })), "summons", "a space mission of another trainer in the datapad")
	lu.assertEquals(opens(T.pilot({ datapad = "duty" })), "summons", "a duty in the datapad")
	lu.assertEquals(opens(T.pilot({ duty = S.DUTY6 })), "summons", "a Dravis duty running")
	lu.assertEquals(opens(T.pilot({ ship = false })), "summons", "no certified ship (Karrde does not read it)")
end

-- K10
-- AC-6, D-4: won and paid
function TestSmugglerTransGates:test_a_won_chain_that_shamdon_has_paid_opens_low_profile()
	lu.assertEquals(opens(T.pilot({ trans = "won", rewarded = true })), "low_profile", "both complete, :reward = 1")
end

-- AC-6: the rows keep the K order when the state mixes (a paid key with a cleared chain, a paid key with a running one, a won chain without the skills)
function TestSmugglerTransGates:test_the_rows_keep_their_order_for_mixed_states()
	lu.assertEquals(opens(T.pilot({ trans = "attempted", rewarded = true })), "trans_failed", "paid key but the chain is gone: K4 first")
	lu.assertEquals(opens(T.pilot({ trans = "active", rewarded = true })), "on_trans", "paid key with a running chain: K7 before K10")
	lu.assertEquals(opens(T.pilot({ trans = "won", tier = 3 })), "dravis_employee", "a won chain but only three tier 1 skills: K5 comes before K6")
end

---------------------------------------------------------------------------------------------
-- Helpers (Content contract 3)
---------------------------------------------------------------------------------------------

TestSmugglerTransHelpers = {}

function TestSmugglerTransHelpers:setUp()
	H.reset()
	T.requireConversation(lu)
end

-- AC-1, AC-6: isOnTransQuest = either quest of the chain is active
function TestSmugglerTransHelpers:test_isOnTransQuest_is_true_while_either_quest_is_active()
	local h = T.handler()

	lu.assertFalse(h:isOnTransQuest(T.pilot({})), "no state")
	lu.assertFalse(h:isOnTransQuest(T.pilot({ trans = "attempted" })), "failed")
	lu.assertTrue(h:isOnTransQuest(T.pilot({ trans = "active" })), "patrol active")
	lu.assertTrue(h:isOnTransQuest(T.pilot({ trans = "child_active" })), "assassinate active")
	lu.assertFalse(h:isOnTransQuest(T.pilot({ trans = "won" })), "won")
	lu.assertFalse(h:isOnTransQuest(T.pilot({ trans = "patrol_only" })), "patrol complete only")
end

-- AC-1, AC-6: hasFailedTransQuest = attempted, not won, not running
function TestSmugglerTransHelpers:test_hasFailedTransQuest_is_attempted_and_neither_won_nor_running()
	local h = T.handler()

	lu.assertFalse(h:hasFailedTransQuest(T.pilot({})), "never asked")
	lu.assertTrue(h:hasFailedTransQuest(T.pilot({ trans = "attempted" })), "failed or aborted")
	lu.assertTrue(h:hasFailedTransQuest(T.pilot({ trans = "patrol_only" })), "patrol complete, assassinate never started")
	lu.assertFalse(h:hasFailedTransQuest(T.pilot({ trans = "active" })), "running")
	lu.assertFalse(h:hasFailedTransQuest(T.pilot({ trans = "child_active" })), "assassinate running")
	lu.assertFalse(h:hasFailedTransQuest(T.pilot({ trans = "won" })), "won")

	local noKey = T.pilot({})

	T.setState(noKey, T.PATROL, "complete")
	lu.assertFalse(h:hasFailedTransQuest(noKey), "patrol complete but never attempted through Karrde (no :attempted key)")
end

-- AC-9: hasWonTransQuest needs both quests complete
function TestSmugglerTransHelpers:test_hasWonTransQuest_needs_both_quests_complete()
	local sq = T.squadron()

	lu.assertFalse(sq:hasWonTransQuest(nil), "nil player")
	lu.assertFalse(sq:hasWonTransQuest(T.pilot({})), "no state")
	lu.assertFalse(sq:hasWonTransQuest(T.pilot({ trans = "active" })), "patrol active")
	lu.assertFalse(sq:hasWonTransQuest(T.pilot({ trans = "patrol_only" })), "patrol complete only")
	lu.assertFalse(sq:hasWonTransQuest(T.pilot({ trans = "child_active" })), "assassinate active")
	lu.assertTrue(sq:hasWonTransQuest(T.pilot({ trans = "won" })), "both complete")

	local asnOnly = T.pilot({})

	T.setState(asnOnly, T.ASSASSINATE, "complete")
	lu.assertFalse(sq:hasWonTransQuest(asnOnly), "assassinate complete only")
end

---------------------------------------------------------------------------------------------
-- I-9: the gates are pure
---------------------------------------------------------------------------------------------

TestSmugglerTransPureGates = {}

function TestSmugglerTransPureGates:setUp()
	H.reset()
	T.requireConversation(lu)
end

-- every pilot of AC-6, by name
local PILOTS = {
	{ "never_asked", {} },
	{ "pilot_tier_1", { pilotTier = 1 } },
	{ "no_skills", { tier = 0, paid = 0, pilotTier = 1 } },
	{ "two_skills", { tier = 2, paid = 2, pilotTier = 1 } },
	{ "three_skills", { tier = 3, paid = 3, pilotTier = 1 } },
	{ "non_pilot", { pilot = false, squadron = false, tier = 0, paid = 0 } },
	{ "rebel_pilot", { pilot = "rebel", squadron = false } },
	{ "imperial_pilot", { pilot = "imperial", squadron = false } },
	{ "corsec_pilot", { squadron = CORSEC_SQUADRON } },
	{ "rsf_pilot", { squadron = RSF_SQUADRON } },
	{ "attempted", { trans = "attempted" } },
	{ "patrol_active", { trans = "active" } },
	{ "assassinate_active", { trans = "child_active" } },
	{ "patrol_only", { trans = "patrol_only" } },
	{ "won", { trans = "won" } },
	{ "paid", { trans = "won", rewarded = true } },
	{ "other_quest_in_datapad", { datapad = "story" } },
	{ "dravis_duty", { duty = S.DUTY6 } },
	{ "no_ship", { ship = false } },
}

-- I-9: no skill, item, ship, quest start, journal, status, observer, waypoint, datapad or shared-memory change on the first screen
function TestSmugglerTransPureGates:test_getInitialScreen_changes_nothing_for_any_pilot()
	local starts = {}

	for _, g in ipairs(T.GLOBALS) do
		starts[g] = H.spyOn(T.quest(g), "startQuest")
	end

	for _, p in ipairs(PILOTS) do
		local name, opts = p[1], p[2]
		local player = T.pilot(opts)
		local before = MS.snapshot(player)
		local sideBefore = MS.sideEffects(player)
		local free0, bought0, items0, ships0 = #S.free(), #S.bought(), #H.Engine.callsTo("giveItem"), #H.Engine.callsTo("grantStarterShip")
		local n0 = {}

		for _, g in ipairs(T.GLOBALS) do
			n0[g] = #starts[g]
		end

		local screen = T.handler():getInitialScreen(player, T.npc(), H.conversationTemplate(T.TEMPLATE))

		lu.assertNotNil(screen, name .. ": a first screen")
		lu.assertEquals(MS.snapshot(player), before, name .. ": journal, statuses, observers, waypoints, datapad and shared memory")
		lu.assertEquals(MS.sideEffects(player), sideBefore, name .. ": messages, music and events")
		lu.assertEquals({ #S.free(), #S.bought(), #H.Engine.callsTo("giveItem"), #H.Engine.callsTo("grantStarterShip") }, { free0, bought0, items0, ships0 },
			name .. ": awardSkill, skillManagerAwardSkill, giveItem, grantStarterShip calls")

		for _, g in ipairs(T.GLOBALS) do
			lu.assertEquals(#starts[g], n0[g], name .. ": " .. g .. ":startQuest calls")
		end

		lu.assertEquals(player.bankCredits or 0, 0, name .. ": credits")
	end
end

-- I-9: the first screen is the same on every call
function TestSmugglerTransPureGates:test_getInitialScreen_answers_the_same_every_time()
	for _, p in ipairs(PILOTS) do
		local player = T.pilot(p[2])
		local first = T.handler():getInitialScreen(player, T.npc(), H.conversationTemplate(T.TEMPLATE))
		local again = T.handler():getInitialScreen(player, T.npc(), H.conversationTemplate(T.TEMPLATE))

		lu.assertEquals(again, first, p[1] .. ": the screen of a repeated call")
	end
end

-- AC-5 (every transcript resolves in the client): the first screen of every pilot above
function TestSmugglerTransPureGates:test_every_first_screen_resolves_in_the_client()
	for _, p in ipairs(PILOTS) do
		H.reset()

		local t = T.talk(T.pilot(p[2]))

		lu.assertEquals(CS.transcriptUnresolved(t), {}, p[1] .. ": client strings of the first screen")
	end
end
