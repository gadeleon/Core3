-- Declann's first screen: gate table P (P0 to P18), first match wins.
-- Spec: .claude/work/space-master-trainer-imperial/01-spec.md (AC-5; Conversation flow 1; D-3, D-4, D-8; J:4686-5115).
--
-- Each row gets a pilot built to satisfy that row and none above it; the pairs test proves each earlier row wins over the later one when both hold.

local lu = require("luaunit")
local H = require("harness")
local M = require("master_trainer_imperial_data")
local CS = require("harness.client_strings")

M.load()

local function setUp()
	H.reset()
	M.requireConversation(lu)
end

local function opens(player) return M.firstScreen(player) end

local function handler() return rawget(_G, M.HANDLER) end

TestMasterTrainerImperialGates = {}

TestMasterTrainerImperialGates.setUp = setUp

-- P0
-- AC-5
function TestMasterTrainerImperialGates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = M.pilot(), M.npc(), H.conversationTemplate(M.TEMPLATE)

	lu.assertNil(handler():getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(handler():getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(handler():getInitialScreen(player, npc, nil), "no template")
end

-- P1
-- AC-5
function TestMasterTrainerImperialGates:test_jtl_disabled_opens_default()
	H.Engine.config.jtlEnabled = false

	lu.assertEquals(opens(M.pilot()), "default", "JTL disabled")
	lu.assertEquals(opens(M.pilot({ keys = { rebel = true } })), "default", "JTL disabled beats the Rebel key")
end

-- P1
-- AC-5
function TestMasterTrainerImperialGates:test_a_pilot_without_a_player_object_opens_default()
	local player = M.pilot()

	player.ghost = nil
	lu.assertEquals(opens(player), "default", "ghost is nil")
end

-- P2
-- AC-5
function TestMasterTrainerImperialGates:test_a_pilot_holding_the_rebel_master_key_opens_working_for_rebellion()
	lu.assertEquals(opens(M.pilot({ keys = { rebel = true } })), "working_for_rebellion", "Imperial pilot with the key")
	lu.assertEquals(opens(M.pilot({ keys = { rebel = true }, kind = "neutral" })), "working_for_rebellion", "CorSec pilot with the key")
	lu.assertEquals(opens(M.pilot({ keys = { rebel = true }, kind = false })), "working_for_rebellion", "a non-pilot with the key")
	lu.assertEquals(opens(M.pilot({ keys = { rebel = true }, t4 = 2 })), "working_for_rebellion", "the key beats the readiness check")
end

-- P3
-- AC-5
function TestMasterTrainerImperialGates:test_a_rebel_pilot_opens_rebel_pilot()
	lu.assertEquals(opens(M.pilot({ kind = "rebel" })), "rebel_pilot", "Havoc pilot with four tier 4 skills")
	lu.assertEquals(opens(M.pilot({ kind = "rebel", t4 = 0 })), "rebel_pilot", "Havoc pilot with no tier 4 skill")
	lu.assertEquals(opens(M.pilot({ kind = "rebel", master = true })), "rebel_pilot", "a Rebel pilot who holds his own master skill")
end

-- P4
-- AC-5
function TestMasterTrainerImperialGates:test_a_smuggler_squadron_pilot_opens_smuggler()
	lu.assertEquals(opens(M.pilot({ kind = "neutral", squadron = "smuggler" })), "smuggler", "Smuggler pilot with four tier 4 skills")
	lu.assertEquals(opens(M.pilot({ kind = "neutral", squadron = "smuggler", t4 = 1 })), "smuggler", "Smuggler pilot with one tier 4 skill")
end

-- P5
-- AC-5
function TestMasterTrainerImperialGates:test_an_imperial_pilot_with_fewer_than_four_tier_4_skills_opens_not_ready()
	for have = 0, 3 do
		lu.assertEquals(opens(M.pilot({ t4 = have })), "not_ready", "Black Epsilon pilot with " .. have .. " tier 4 skills")
	end

	lu.assertEquals(opens(M.pilot({ t4 = 3, squadron = "storm" })), "not_ready", "Storm pilot with three tier 4 skills")
end

-- P5: the walk ends after one reply
-- AC-5
function TestMasterTrainerImperialGates:test_not_ready_offers_sorry_sir_and_the_walk_ends_on_not_ready_sorry()
	local t = M.talk(M.pilot({ t4 = 3 }), { "s_f2aa6939" })

	lu.assertEquals(M.ids(t), { "not_ready", "not_ready_sorry" }, "screens shown")
	lu.assertFalse(t[1].stop, "not_ready waits for the reply")
	lu.assertTrue(t[2].stop, "not_ready_sorry ends the walk")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- P6
-- AC-5
function TestMasterTrainerImperialGates:test_a_corsec_or_rsf_pilot_with_fewer_than_four_neutral_tier_4_skills_opens_privateer_not_ready()
	lu.assertEquals(opens(M.pilot({ kind = "neutral", t4 = 3 })), "privateer_not_ready", "CorSec pilot with three neutral tier 4 skills")
	lu.assertEquals(opens(M.pilot({ kind = "neutral", t4 = 0 })), "privateer_not_ready", "CorSec pilot with none")
	lu.assertEquals(opens(M.pilot({ kind = "neutral", squadron = "rsf", t4 = 2 })), "privateer_not_ready", "RSF pilot with two")
end

-- P7
-- AC-5
function TestMasterTrainerImperialGates:test_a_pilot_who_holds_the_neutral_master_skill_opens_other_master()
	lu.assertEquals(opens(M.pilot({ otherMaster = "neutral" })), "other_master", "Imperial pilot with all four tier 4 skills and pilot_neutral_master")
	lu.assertEquals(opens(M.pilot({ kind = "neutral", master = true })), "other_master", "CorSec pilot with pilot_neutral_master")
end

-- P8
-- AC-5
function TestMasterTrainerImperialGates:test_a_pilot_who_holds_the_imperial_master_skill_opens_master_done()
	lu.assertEquals(opens(M.pilot({ master = true })), "master_done", "Black Epsilon master")
	lu.assertEquals(opens(M.pilot({ master = true, squadron = "storm" })), "master_done", "Storm master")
	lu.assertEquals(opens(M.pilot({ master = true, paid = { 1, 2 } })), "master_done", "master with both missions paid")
end

-- P9
-- AC-5
function TestMasterTrainerImperialGates:test_a_pilot_flying_a_master_mission_opens_on_master_mission_not_on_quest()
	lu.assertEquals(opens(M.pilot({ mission = { [1] = "active" } })), "on_master_mission", "mission 1 running, no datapad mission")
	lu.assertEquals(opens(M.pilot({ mission = { [2] = "active" }, paid = { 1 } })), "on_master_mission", "mission 2 running")
	lu.assertEquals(opens(M.pilot({ mission = { [1] = "active" }, datapad = "story" })), "on_master_mission", "mission 1 running with its datapad mission")
	lu.assertEquals(opens(M.pilot({ mission = { [1] = "active" }, other = "patrol_corellia_imperial_tier4_1" })), "on_master_mission", "the master mission wins over another trainer's quest")
end

-- P10
-- AC-5
function TestMasterTrainerImperialGates:test_a_pilot_holding_a_duty_or_a_quest_of_another_trainer_opens_on_quest()
	lu.assertEquals(opens(M.pilot({ other = "patrol_corellia_imperial_tier4_1" })), "on_quest", "a Nin Gursawe quest in the datapad")
	lu.assertEquals(opens(M.pilot({ datapad = "duty" })), "on_quest", "a duty in the datapad")
	lu.assertEquals(opens(M.pilot({ datapad = "story" })), "on_quest", "a story mission in the datapad")
	lu.assertEquals(opens(M.pilot({ datapad = "duty", paid = { 1 } })), "on_quest", "a duty after mission 1 was paid")
end

-- P11
-- AC-5
function TestMasterTrainerImperialGates:test_a_failed_mission_2_opens_m2_failed_even_when_mission_1_is_won_and_paid()
	lu.assertEquals(opens(M.pilot({ paid = { 1 }, mission = { [2] = "failed" } })), "m2_failed", "M1 paid, M2 attempted and not won")
	lu.assertEquals(opens(M.pilot({ paid = { 1 }, mission = { [2] = "failed" }, xp = 5 })), "m2_failed", "the same with XP")
end

-- P12
-- AC-5
function TestMasterTrainerImperialGates:test_a_failed_mission_1_opens_m1_failed()
	lu.assertEquals(opens(M.pilot({ mission = { [1] = "failed" } })), "m1_failed", "M1 attempted and not won")
	lu.assertEquals(opens(M.pilot({ mission = { [1] = "attempted" } })), "m1_failed", "M1 attempted (aborted)")
end

-- P13
-- AC-5
function TestMasterTrainerImperialGates:test_a_won_unpaid_mission_2_opens_m2_won()
	lu.assertEquals(opens(M.pilot({ paid = { 1 }, mission = { [2] = "won" } })), "m2_won", "M1 paid, M2 won")
	lu.assertEquals(opens(M.pilot({ mission = { [1] = "won", [2] = "won" } })), "m2_won", "M1 and M2 both won, nothing paid: mission 2 first")
end

-- P14
-- AC-5
function TestMasterTrainerImperialGates:test_a_won_unpaid_mission_1_opens_m1_won()
	lu.assertEquals(opens(M.pilot({ mission = { [1] = "won" } })), "m1_won", "M1 won and unpaid")
end

-- P15
-- AC-5
function TestMasterTrainerImperialGates:test_a_paid_mission_1_opens_m2_brief_for_an_imperial_pilot()
	lu.assertEquals(opens(M.pilot({ paid = { 1 } })), "m2_brief", "M1 paid, M2 never attempted")
	lu.assertEquals(opens(M.pilot({ paid = { 1 }, squadron = "inquisition" })), "m2_brief", "Inquisition pilot")
end

-- P16
-- AC-5
function TestMasterTrainerImperialGates:test_a_ready_imperial_pilot_opens_intro_whatever_the_squadron()
	lu.assertEquals(opens(M.pilot({})), "intro", "Black Epsilon pilot with four tier 4 skills")
	lu.assertEquals(opens(M.pilot({ squadron = "storm" })), "intro", "Storm pilot (D-3)")
	lu.assertEquals(opens(M.pilot({ squadron = "inquisition" })), "intro", "Inquisition pilot (D-3)")
	lu.assertEquals(opens(M.pilot({ squadron = false })), "intro", "Imperial pilot with no squadron")
end

-- P16, D-3: Nin's hand-off flag changes no gate
-- AC-5
function TestMasterTrainerImperialGates:test_nins_declann_flag_changes_no_gate_set_or_unset()
	local cases = {
		{ name = "ready", o = {}, want = "intro" },
		{ name = "not ready", o = { t4 = 2 }, want = "not_ready" },
		{ name = "M1 won", o = { mission = { [1] = "won" } }, want = "m1_won" },
		{ name = "M1 paid", o = { paid = { 1 } }, want = "m2_brief" },
		{ name = "master", o = { master = true }, want = "master_done" },
	}

	for _, c in ipairs(cases) do
		local plain, flagged = {}, { keys = { nin = true } }

		for k, v in pairs(c.o) do
			plain[k] = v
			flagged[k] = v
		end

		lu.assertEquals(opens(M.pilot(plain)), c.want, c.name .. ": Nin's flag unset")
		lu.assertEquals(opens(M.pilot(flagged)), c.want, c.name .. ": Nin's flag set")
	end
end

-- D-8: no wanted gate, no grounded gate
-- AC-5
function TestMasterTrainerImperialGates:test_negative_imperial_standing_does_not_block_declann()
	lu.assertEquals(opens(M.pilot({ standing = -300 })), "intro", "standing -300 on a ready pilot")
	lu.assertEquals(opens(M.pilot({ standing = -1, paid = { 1 } })), "m2_brief", "standing -1 after mission 1")
	lu.assertEquals(opens(M.pilot({ standing = -50, mission = { [1] = "won" } })), "m1_won", "standing -50 with a won mission")
end

-- D-8: no grounded gate
-- AC-5
function TestMasterTrainerImperialGates:test_a_pilot_without_a_certified_ship_is_not_refused()
	local player = M.pilot({})

	player.certifiedShip = false
	lu.assertEquals(opens(player), "intro", "no certified ship")
end

-- P17, D-4
-- AC-5
-- Superseded by space-master-trainer-privateer (D-13): CorSec and RSF pilots now open privateer_ready_corsec / _rsf (test_master_trainer_privateer_gates.lua);
-- only a ready neutral pilot with no squadron still opens the curt privateer_ready.
function TestMasterTrainerImperialGates:test_a_ready_privateer_opens_privateer_ready_which_ends_with_no_reply()
	local t = M.talk(M.pilot({ kind = "neutral", squadron = false }), { 0 })

	lu.assertEquals(M.ids(t), { "privateer_ready" }, "a no-squadron neutral pilot with four neutral tier 4 skills sees the curt opener and nothing more")
	lu.assertTrue(t[1].stop, "privateer_ready ends the conversation")
	lu.assertEquals(#t[1].options, 0, "privateer_ready offers no reply")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- P17: a ready privateer is not offered a mission or a reward
-- AC-5
-- (space-master-trainer-privateer: the pilot has no squadron, as in the test above)
function TestMasterTrainerImperialGates:test_a_ready_privateer_gets_nothing_started_or_paid()
	local spies = M.spyStarts()
	local player = M.pilot({ kind = "neutral", squadron = false })

	M.talk(player)
	lu.assertEquals(M.started(spies), {}, "quests started")
	lu.assertEquals(player.bankCredits or 0, 0, "bank credits")
	lu.assertEquals(M.standing(player), 0, "standing")
	lu.assertNil(H.getQuestStatus(player, "master_imperial_1:attempted"), "no :attempted key")
end

-- P18
-- AC-5
function TestMasterTrainerImperialGates:test_a_non_pilot_opens_default()
	lu.assertEquals(opens(M.pilot({ kind = false })), "default", "no pilot skills, Imperial faction")
	lu.assertEquals(opens(M.pilot({ kind = false, squadron = false, standing = -3 })), "default", "no pilot skills, negative standing")
end

-- Every row, in one place: the screen, its text and the end flag come from Appendix A
-- AC-5
function TestMasterTrainerImperialGates:test_each_gate_screen_shows_its_appendix_a_text_and_end_flag()
	local cases = {
		{ "default", M.pilot({ kind = false }) },
		{ "working_for_rebellion", M.pilot({ keys = { rebel = true } }) },
		{ "rebel_pilot", M.pilot({ kind = "rebel" }) },
		{ "smuggler", M.pilot({ kind = "neutral", squadron = "smuggler" }) },
		{ "not_ready", M.pilot({ t4 = 1 }) },
		{ "privateer_not_ready", M.pilot({ kind = "neutral", t4 = 1 }) },
		{ "other_master", M.pilot({ otherMaster = "neutral" }) },
		{ "master_done", M.pilot({ master = true }) },
		{ "on_master_mission", M.pilot({ mission = { [1] = "active" } }) },
		{ "on_quest", M.pilot({ datapad = "story" }) },
		{ "m2_failed", M.pilot({ paid = { 1 }, mission = { [2] = "failed" } }) },
		{ "m1_failed", M.pilot({ mission = { [1] = "failed" } }) },
		{ "m2_won", M.pilot({ paid = { 1 }, mission = { [2] = "won" } }) },
		{ "m1_won", M.pilot({ mission = { [1] = "won" } }) },
		{ "m2_brief", M.pilot({ paid = { 1 } }) },
		{ "intro", M.pilot({}) },
		{ "privateer_ready", M.pilot({ kind = "neutral", squadron = false }) }, -- space-master-trainer-privateer: CorSec/RSF open their own gate screens now
	}

	for _, c in ipairs(cases) do
		local t = M.talk(c[2])
		local row = M.ROWS[c[1]]

		lu.assertEquals(t[1].id, c[1], "first screen")
		lu.assertEquals(t[1].stop, row.stop, c[1] .. ": end flag")
		lu.assertEquals(t[1].text, M.PREFIX .. row.sid, c[1] .. ": dialog text id")
		lu.assertEquals(CS.transcriptUnresolved({ t[1] }), {}, c[1] .. ": client strings")
	end
end

-- Precedence: for each adjacent pair of rows a pilot satisfying both opens the earlier one
-- AC-5
function TestMasterTrainerImperialGates:test_an_earlier_row_wins_over_every_later_row_it_overlaps()
	-- P2 over P3 and P5
	lu.assertEquals(opens(M.pilot({ kind = "rebel", keys = { rebel = true } })), "working_for_rebellion", "P2 over P3")
	-- P3 over P4 (a Rebel pilot in the Smuggler squadron)
	lu.assertEquals(opens(M.pilot({ kind = "rebel", squadron = "smuggler" })), "rebel_pilot", "P3 over P4")
	-- P4 over P6 and P17
	lu.assertEquals(opens(M.pilot({ kind = "neutral", squadron = "smuggler", t4 = 4 })), "smuggler", "P4 over P17")
	-- P5 over P8, P9, P11 (an Imperial pilot short of a skill who holds the master skill or has a failed mission)
	lu.assertEquals(opens(M.pilot({ t4 = 3, master = true })), "not_ready", "P5 over P8")
	lu.assertEquals(opens(M.pilot({ t4 = 3, mission = { [1] = "active" } })), "not_ready", "P5 over P9")
	lu.assertEquals(opens(M.pilot({ t4 = 3, mission = { [1] = "failed" } })), "not_ready", "P5 over P12")
	-- P7 over P8 (both master skills)
	lu.assertEquals(opens(M.pilot({ master = true, otherMaster = "neutral" })), "other_master", "P7 over P8")
	-- P8 over P9, P10, P11, P13
	lu.assertEquals(opens(M.pilot({ master = true, mission = { [1] = "active" } })), "master_done", "P8 over P9")
	lu.assertEquals(opens(M.pilot({ master = true, datapad = "story" })), "master_done", "P8 over P10")
	lu.assertEquals(opens(M.pilot({ master = true, mission = { [2] = "won" } })), "master_done", "P8 over P13")
	-- P9 over P10
	lu.assertEquals(opens(M.pilot({ mission = { [1] = "active" }, datapad = "duty" })), "on_master_mission", "P9 over P10")
	-- P10 over P11, P12, P13, P14, P15
	lu.assertEquals(opens(M.pilot({ datapad = "duty", mission = { [1] = "failed" } })), "on_quest", "P10 over P12")
	lu.assertEquals(opens(M.pilot({ datapad = "duty", mission = { [1] = "won" } })), "on_quest", "P10 over P14")
	-- P11 over P12 and P13
	lu.assertEquals(opens(M.pilot({ mission = { [1] = "failed", [2] = "failed" } })), "m2_failed", "P11 over P12")
	lu.assertEquals(opens(M.pilot({ paid = { 1 }, mission = { [2] = "failed" } })), "m2_failed", "P11 with M1 paid")
	-- P12 over P14
	lu.assertEquals(opens(M.pilot({ mission = { [1] = "failed" }, paid = {} })), "m1_failed", "P12")
	-- P13 over P14 and P15
	lu.assertEquals(opens(M.pilot({ mission = { [1] = "won", [2] = "won" } })), "m2_won", "P13 over P14")
	-- P14 over P15 (M1 won, unpaid: not yet paid, so the m1_won screen, not the brief)
	lu.assertEquals(opens(M.pilot({ mission = { [1] = "won" } })), "m1_won", "P14 over P15")
end

-- AC-5: a won and paid mission 1 never shows its reward again
function TestMasterTrainerImperialGates:test_a_paid_mission_1_is_not_shown_as_won_again()
	local first = opens(M.pilot({ paid = { 1 } }))

	lu.assertNotEquals(first, "m1_won", "a paid mission 1 opens the mission 2 briefing, not the reward")
	lu.assertEquals(first, "m2_brief", "the mission 2 briefing")
end

-- AC-5: the opening is a function of state only: two talks in a row from the same state open the same screen
function TestMasterTrainerImperialGates:test_the_opening_screen_is_the_same_for_two_talks_from_the_same_state()
	local player = M.pilot({})

	lu.assertEquals(opens(player), "intro", "first talk")
	lu.assertEquals(opens(player), "intro", "second talk (nothing was granted by reading the intro)")
	lu.assertEquals(H.getQuestStatus(player, "master_imperial_1:attempted"), nil, "no :attempted key set by the opening alone")
end
