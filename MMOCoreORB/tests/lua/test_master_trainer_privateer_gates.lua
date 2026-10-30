-- Privateers at the admirals: the first screen (gate tables PD and PB), first match wins.
-- Spec: .claude/work/space-master-trainer-privateer/01-spec.md (AC-3, AC-4; Conversation flow 1; D-12, D-13; J:4686-5115, RJ:3325-3720).
--
-- Each new or changed row gets a pilot built to satisfy it and no earlier row; the precedence pairs prove an earlier row wins over a later one.
-- The earlier gate cases (IMP P0-P18, REB P0-P18) stay in test_master_trainer_{imperial,rebel}_gates.lua.

local lu = require("luaunit")
local H = require("harness")
local P = require("master_trainer_privateer_data")
local CS = require("harness.client_strings")

P.load()

local function setUp()
	H.reset()
	P.requireConversations(lu)
end

local function opens(adm, o) return P.firstScreen(adm, P.pilot(adm, o)) end

TestMasterTrainerPrivateerDeclannGates = {}

TestMasterTrainerPrivateerDeclannGates.setUp = setUp

-- P17a
-- AC-3
function TestMasterTrainerPrivateerDeclannGates:test_a_ready_rsf_pilot_opens_privateer_ready_rsf_with_the_single_rsf_reply()
	local t = P.talk("declann", P.pilot("declann", { squadron = "rsf" }))

	lu.assertEquals(P.ids(t), { "privateer_ready_rsf" }, "screens shown")
	lu.assertFalse(t[1].stop, "privateer_ready_rsf waits for the reply")
	lu.assertEquals(#t[1].options, 1, "exactly one reply")
	lu.assertEquals(t[1].options[1].text, "@conversation/imperial_master_trainer:s_308a9ab1", "the RSF reply (J isRSF)")
	lu.assertEquals(t[1].text, "@conversation/imperial_master_trainer:s_10009b23", "dialog text id (shared with privateer_ready)")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- P17b
-- AC-3
function TestMasterTrainerPrivateerDeclannGates:test_a_ready_corsec_pilot_opens_privateer_ready_corsec_with_the_single_corsec_reply()
	local t = P.talk("declann", P.pilot("declann", { squadron = "corsec" }))

	lu.assertEquals(P.ids(t), { "privateer_ready_corsec" }, "screens shown")
	lu.assertFalse(t[1].stop, "privateer_ready_corsec waits for the reply")
	lu.assertEquals(#t[1].options, 1, "exactly one reply")
	lu.assertEquals(t[1].options[1].text, "@conversation/imperial_master_trainer:s_8409f60e", "the CorSec reply (J isCorsec)")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- The default neutral builder is a CorSec pilot (spec: M.pilot{ kind = "neutral" })
-- AC-3
function TestMasterTrainerPrivateerDeclannGates:test_the_default_neutral_pilot_is_a_corsec_pilot_and_opens_the_corsec_gate()
	lu.assertEquals(P.firstScreen("declann", P.ADMIRALS.declann.M.pilot({ kind = "neutral" })), "privateer_ready_corsec", "default neutral pilot")
end

-- P17 (D-13)
-- AC-3
function TestMasterTrainerPrivateerDeclannGates:test_a_ready_neutral_pilot_with_no_squadron_still_opens_the_curt_privateer_ready()
	local t = P.talk("declann", P.pilot("declann", { squadron = false }))

	lu.assertEquals(P.ids(t), { "privateer_ready" }, "screens shown")
	lu.assertTrue(t[1].stop, "privateer_ready ends the conversation")
	lu.assertEquals(#t[1].options, 0, "privateer_ready offers no reply")
end

-- P4
-- AC-3
function TestMasterTrainerPrivateerDeclannGates:test_a_ready_smuggler_opens_smuggler()
	lu.assertEquals(opens("declann", { squadron = "smuggler" }), "smuggler", "ready Smuggler")
	lu.assertEquals(opens("declann", { squadron = "smuggler", paid = { 1 } }), "smuggler", "Smuggler with a paid mission 1")
	lu.assertEquals(opens("declann", { squadron = "smuggler", master = true }), "smuggler", "Smuggler with the master skill")
end

-- P15a
-- AC-3
function TestMasterTrainerPrivateerDeclannGates:test_a_privateer_with_mission_1_paid_opens_priv_m2_brief()
	for _, squadron in ipairs({ "corsec", "rsf", false }) do
		lu.assertEquals(opens("declann", { squadron = squadron, paid = { 1 } }), "priv_m2_brief", tostring(squadron) .. ": neutral pilot, M1 paid, M2 never attempted")
	end
end

-- P15
-- AC-3
function TestMasterTrainerPrivateerDeclannGates:test_an_imperial_pilot_with_mission_1_paid_still_opens_m2_brief()
	lu.assertEquals(opens("declann", { kind = "imperial", paid = { 1 } }), "m2_brief", "Black Epsilon pilot, M1 paid")
	lu.assertEquals(opens("declann", { kind = "imperial", squadron = "storm", paid = { 1 } }), "m2_brief", "Storm pilot, M1 paid")
end

-- P2
-- AC-3
function TestMasterTrainerPrivateerDeclannGates:test_a_corsec_pilot_holding_the_rebel_key_opens_working_for_rebellion_in_every_state()
	local states = {
		{ name = "ready", o = {} },
		{ name = "with pilot_neutral_master", o = { master = true } },
		{ name = "M1 won", o = { mission = { [1] = "won" } } },
		{ name = "M1 paid", o = { paid = { 1 } } },
		{ name = "M2 failed", o = { paid = { 1 }, mission = { [2] = "failed" } } },
		{ name = "M1 active", o = { mission = { [1] = "active" } } },
		{ name = "not ready (two tier 4 skills)", o = { t4 = 2 } },
		{ name = "a duty in the datapad", o = { datapad = "duty" } },
	}

	for _, s in ipairs(states) do
		local o = { keys = { rebel = true } }

		for k, v in pairs(s.o) do
			o[k] = v
		end

		lu.assertEquals(opens("declann", o), "working_for_rebellion", "CorSec pilot with the Rebel key, " .. s.name)
	end
end

-- P7
-- AC-3
function TestMasterTrainerPrivateerDeclannGates:test_privateers_holding_pilot_neutral_master_without_a_key_open_other_master()
	for _, squadron in ipairs({ "corsec", "rsf", false }) do
		lu.assertEquals(opens("declann", { squadron = squadron, master = true }), "other_master", tostring(squadron) .. ": master, no key")
		lu.assertEquals(opens("declann", { squadron = squadron, master = true, paid = { 1, 2 } }), "other_master", tostring(squadron) .. ": master, both missions paid")
	end

	-- the CorSec pilot who flew for Declann: his own key does not refuse him
	lu.assertEquals(opens("declann", { master = true, paid = { 1, 2 }, keys = { imperial = true } }), "other_master", "master with Declann's own key")
end

-- P6 / P9 / P10 / P11 / P12 / P13 / P14: the privateer follows the shared rows
-- AC-3
function TestMasterTrainerPrivateerDeclannGates:test_a_privateer_follows_the_shared_state_rows()
	local cases = {
		{ "privateer_not_ready", { t4 = 3 } },
		{ "on_master_mission", { mission = { [1] = "active" }, keys = { imperial = true } } },
		{ "on_master_mission", { paid = { 1 }, mission = { [2] = "active" }, keys = { imperial = true } } },
		{ "on_quest", { datapad = "duty", keys = { imperial = true } } },
		{ "m2_failed", { paid = { 1 }, mission = { [2] = "failed" }, keys = { imperial = true } } },
		{ "m1_failed", { mission = { [1] = "failed" }, keys = { imperial = true } } },
		{ "m1_failed", { mission = { [1] = "attempted" }, keys = { imperial = true } } },
		{ "m2_won", { paid = { 1 }, mission = { [2] = "won" }, keys = { imperial = true } } },
		{ "m1_won", { mission = { [1] = "won" }, keys = { imperial = true } } },
		{ "priv_m2_brief", { paid = { 1 }, keys = { imperial = true } } },
	}

	for _, squadron in ipairs({ "corsec", "rsf" }) do
		for _, c in ipairs(cases) do
			local o = { squadron = squadron }

			for k, v in pairs(c[2]) do
				o[k] = v
			end

			lu.assertEquals(opens("declann", o), c[1], squadron .. " privateer for " .. c[1])
		end
	end
end

-- Precedence: an earlier row wins over every later row it overlaps
-- AC-3
function TestMasterTrainerPrivateerDeclannGates:test_an_earlier_row_wins_over_the_privateer_gate_rows()
	-- P2 over P17a / P17b
	lu.assertEquals(opens("declann", { squadron = "corsec", keys = { rebel = true } }), "working_for_rebellion", "P2 over P17b")
	lu.assertEquals(opens("declann", { squadron = "rsf", keys = { rebel = true } }), "working_for_rebellion", "P2 over P17a")
	-- P4 over P17a / P17b
	lu.assertEquals(opens("declann", { squadron = "smuggler" }), "smuggler", "P4 over P17")
	-- P6 over P17a: a privateer one skill short is not ready
	lu.assertEquals(opens("declann", { squadron = "rsf", t4 = 3 }), "privateer_not_ready", "P6 over P17a")
	-- P15a over P17a / P17b: a privateer who was paid mission 1 never sees the gate screens again
	lu.assertEquals(opens("declann", { squadron = "rsf", paid = { 1 } }), "priv_m2_brief", "P15a over P17a")
	lu.assertEquals(opens("declann", { squadron = "corsec", paid = { 1 } }), "priv_m2_brief", "P15a over P17b")
	-- P14 over P15a: mission 1 won and not yet paid
	lu.assertEquals(opens("declann", { squadron = "corsec", mission = { [1] = "won" } }), "m1_won", "P14 over P15a")
	-- P7 over P9: the master skill beats a running mission
	lu.assertEquals(opens("declann", { master = true, mission = { [1] = "active" } }), "other_master", "P7 over P9")
	-- P13 over P15a: mission 2 won and not paid
	lu.assertEquals(opens("declann", { paid = { 1 }, mission = { [2] = "won" } }), "m2_won", "P13 over P15a")
end

-- Every gate screen shows its row's text and end flag
-- AC-3
function TestMasterTrainerPrivateerDeclannGates:test_each_new_gate_screen_shows_its_appendix_text_and_end_flag()
	local cases = {
		{ "privateer_ready_rsf", P.pilot("declann", { squadron = "rsf" }) },
		{ "privateer_ready_corsec", P.pilot("declann", { squadron = "corsec" }) },
		{ "priv_m2_brief", P.pilot("declann", { paid = { 1 } }) },
	}

	for _, c in ipairs(cases) do
		local t = P.talk("declann", c[2])
		local row = P.ADMIRALS.declann.rowsAll[c[1]]

		lu.assertEquals(t[1].id, c[1], "first screen")
		lu.assertEquals(t[1].stop, row.stop, c[1] .. ": end flag")
		lu.assertEquals(t[1].text, P.ADMIRALS.declann.M.PREFIX .. row.sid, c[1] .. ": dialog text id")
		lu.assertEquals(CS.transcriptUnresolved({ t[1] }), {}, c[1] .. ": client strings")
	end
end

-- I-7: opening the gate sets nothing, starts nothing, pays nothing
-- AC-3, AC-5
function TestMasterTrainerPrivateerDeclannGates:test_opening_a_gate_screen_sets_no_key_starts_no_quest_and_pays_nothing()
	for _, squadron in ipairs({ "corsec", "rsf", false }) do
		local spies = P.spyAllStarts()
		local player = P.pilot("declann", { squadron = squadron })

		P.talk("declann", player)
		P.talk("declann", player)

		lu.assertNil(H.getQuestStatus(player, P.ADMIRALS.declann.sideKey), tostring(squadron) .. ": Imperial key")
		lu.assertNil(H.getQuestStatus(player, P.ADMIRALS.declann.otherKey), tostring(squadron) .. ": Rebel key")
		lu.assertNil(H.getQuestStatus(player, "master_imperial_1:attempted"), tostring(squadron) .. ": :attempted")
		lu.assertEquals(player.bankCredits or 0, 0, tostring(squadron) .. ": credits")
		lu.assertEquals(P.standing("declann", player), 0, tostring(squadron) .. ": standing")

		for g, calls in pairs(spies) do
			lu.assertEquals(#calls, 0, tostring(squadron) .. ": " .. g .. " startQuest calls")
		end
	end
end

-- the opening is a function of state only
-- AC-3
function TestMasterTrainerPrivateerDeclannGates:test_two_talks_from_the_same_state_open_the_same_screen()
	for _, squadron in ipairs({ "corsec", "rsf" }) do
		local player = P.pilot("declann", { squadron = squadron })
		local first = P.firstScreen("declann", player)

		lu.assertEquals(P.firstScreen("declann", player), first, squadron .. ": second talk")
	end
end

---------------------------------------------------------------------------------------------
-- Burke
---------------------------------------------------------------------------------------------

TestMasterTrainerPrivateerBurkeGates = {}

TestMasterTrainerPrivateerBurkeGates.setUp = setUp

-- P17a
-- AC-4
function TestMasterTrainerPrivateerBurkeGates:test_a_ready_smuggler_opens_privateer_ready_smuggler_with_the_single_smuggler_reply()
	local t = P.talk("burke", P.pilot("burke", { squadron = "smuggler" }))

	lu.assertEquals(P.ids(t), { "privateer_ready_smuggler" }, "screens shown")
	lu.assertFalse(t[1].stop, "privateer_ready_smuggler waits for the reply")
	lu.assertEquals(#t[1].options, 1, "exactly one reply")
	lu.assertEquals(t[1].options[1].text, "@conversation/rebel_master_trainer:s_2acaca5d", "the Smuggler reply (RJ isSmuggler)")
	lu.assertEquals(t[1].text, "@conversation/rebel_master_trainer:s_41910783", "dialog text id (shared with privateer_ready)")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- P17b
-- AC-4
function TestMasterTrainerPrivateerBurkeGates:test_a_ready_corsec_pilot_opens_privateer_ready_corsec_with_the_single_corsec_reply()
	local t = P.talk("burke", P.pilot("burke", { squadron = "corsec" }))

	lu.assertEquals(P.ids(t), { "privateer_ready_corsec" }, "screens shown")
	lu.assertFalse(t[1].stop, "privateer_ready_corsec waits for the reply")
	lu.assertEquals(#t[1].options, 1, "exactly one reply")
	lu.assertEquals(t[1].options[1].text, "@conversation/rebel_master_trainer:s_dc2fa6d8", "the CorSec reply (RJ isCorsec)")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- P17 (D-13)
-- AC-4
function TestMasterTrainerPrivateerBurkeGates:test_a_ready_neutral_pilot_with_no_squadron_still_opens_the_curt_privateer_ready()
	local t = P.talk("burke", P.pilot("burke", { squadron = false }))

	lu.assertEquals(P.ids(t), { "privateer_ready" }, "screens shown")
	lu.assertTrue(t[1].stop, "privateer_ready ends the conversation")
	lu.assertEquals(#t[1].options, 0, "privateer_ready offers no reply")
end

-- P4
-- AC-4
function TestMasterTrainerPrivateerBurkeGates:test_a_ready_rsf_pilot_opens_rsf_pilot()
	lu.assertEquals(opens("burke", { squadron = "rsf" }), "rsf_pilot", "ready RSF pilot")
	lu.assertEquals(opens("burke", { squadron = "rsf", paid = { 1 } }), "rsf_pilot", "RSF pilot with a paid mission 1")
	lu.assertEquals(opens("burke", { squadron = "rsf", master = true }), "rsf_pilot", "RSF pilot with the master skill")
end

-- P15 (unchanged; serves privateers, REB D-9)
-- AC-4
function TestMasterTrainerPrivateerBurkeGates:test_a_privateer_with_mission_1_paid_opens_m2_brief()
	for _, squadron in ipairs({ "corsec", "smuggler", false }) do
		lu.assertEquals(opens("burke", { squadron = squadron, paid = { 1 } }), "m2_brief", tostring(squadron) .. ": neutral pilot, M1 paid, M2 never attempted")
	end
end

-- P2
-- AC-4
function TestMasterTrainerPrivateerBurkeGates:test_a_corsec_pilot_holding_the_imperial_key_opens_working_for_empire_in_every_state()
	local states = {
		{ name = "ready", o = {} },
		{ name = "with pilot_neutral_master", o = { master = true } },
		{ name = "M1 won", o = { mission = { [1] = "won" } } },
		{ name = "M1 paid", o = { paid = { 1 } } },
		{ name = "M2 failed", o = { paid = { 1 }, mission = { [2] = "failed" } } },
		{ name = "M1 active", o = { mission = { [1] = "active" } } },
		{ name = "not ready (two tier 4 skills)", o = { t4 = 2 } },
		{ name = "a duty in the datapad", o = { datapad = "duty" } },
	}

	for _, s in ipairs(states) do
		local o = { keys = { imperial = true } }

		for k, v in pairs(s.o) do
			o[k] = v
		end

		lu.assertEquals(opens("burke", o), "working_for_empire", "CorSec pilot with the Imperial key, " .. s.name)
	end
end

-- P7
-- AC-4
function TestMasterTrainerPrivateerBurkeGates:test_privateers_holding_pilot_neutral_master_without_a_key_open_other_master()
	for _, squadron in ipairs({ "corsec", "smuggler", false }) do
		lu.assertEquals(opens("burke", { squadron = squadron, master = true }), "other_master", tostring(squadron) .. ": master, no key")
		lu.assertEquals(opens("burke", { squadron = squadron, master = true, paid = { 1, 2 } }), "other_master", tostring(squadron) .. ": master, both missions paid")
	end

	lu.assertEquals(opens("burke", { master = true, paid = { 1, 2 }, keys = { rebel = true } }), "other_master", "master with Burke's own key")
end

-- the privateer follows the shared rows
-- AC-4
function TestMasterTrainerPrivateerBurkeGates:test_a_privateer_follows_the_shared_state_rows()
	local cases = {
		{ "privateer_not_ready", { t4 = 3 } },
		{ "on_master_mission", { mission = { [1] = "active" } } },
		{ "on_master_mission", { paid = { 1 }, mission = { [2] = "active" } } },
		{ "on_quest", { datapad = "duty" } },
		{ "m2_failed", { paid = { 1 }, mission = { [2] = "failed" } } },
		{ "m1_failed", { mission = { [1] = "failed" } } },
		{ "m2_won", { paid = { 1 }, mission = { [2] = "won" } } },
		{ "m1_won", { mission = { [1] = "won" } } },
		{ "m2_brief", { paid = { 1 } } },
	}

	for _, squadron in ipairs({ "corsec", "smuggler" }) do
		for _, c in ipairs(cases) do
			local o = { squadron = squadron }

			for k, v in pairs(c[2]) do
				o[k] = v
			end

			lu.assertEquals(opens("burke", o), c[1], squadron .. " privateer for " .. c[1])
		end
	end
end

-- Precedence
-- AC-4
function TestMasterTrainerPrivateerBurkeGates:test_an_earlier_row_wins_over_the_privateer_gate_rows()
	lu.assertEquals(opens("burke", { squadron = "corsec", keys = { imperial = true } }), "working_for_empire", "P2 over P17b")
	lu.assertEquals(opens("burke", { squadron = "smuggler", keys = { imperial = true } }), "working_for_empire", "P2 over P17a")
	lu.assertEquals(opens("burke", { squadron = "rsf" }), "rsf_pilot", "P4 over P17")
	lu.assertEquals(opens("burke", { squadron = "smuggler", t4 = 3 }), "privateer_not_ready", "P6 over P17a")
	lu.assertEquals(opens("burke", { squadron = "smuggler", paid = { 1 } }), "m2_brief", "P15 over P17a")
	lu.assertEquals(opens("burke", { squadron = "corsec", paid = { 1 } }), "m2_brief", "P15 over P17b")
	lu.assertEquals(opens("burke", { squadron = "corsec", mission = { [1] = "won" } }), "m1_won", "P14 over P15")
	lu.assertEquals(opens("burke", { master = true, mission = { [1] = "active" } }), "other_master", "P7 over P9")
end

-- Every gate screen shows its row's text and end flag
-- AC-4
function TestMasterTrainerPrivateerBurkeGates:test_each_new_gate_screen_shows_its_appendix_text_and_end_flag()
	local cases = {
		{ "privateer_ready_smuggler", P.pilot("burke", { squadron = "smuggler" }) },
		{ "privateer_ready_corsec", P.pilot("burke", { squadron = "corsec" }) },
	}

	for _, c in ipairs(cases) do
		local t = P.talk("burke", c[2])
		local row = P.ADMIRALS.burke.rowsAll[c[1]]

		lu.assertEquals(t[1].id, c[1], "first screen")
		lu.assertEquals(t[1].stop, row.stop, c[1] .. ": end flag")
		lu.assertEquals(t[1].text, P.ADMIRALS.burke.M.PREFIX .. row.sid, c[1] .. ": dialog text id")
		lu.assertEquals(CS.transcriptUnresolved({ t[1] }), {}, c[1] .. ": client strings")
	end
end

-- I-7
-- AC-4, AC-5
function TestMasterTrainerPrivateerBurkeGates:test_opening_a_gate_screen_sets_no_key_starts_no_quest_and_pays_nothing()
	for _, squadron in ipairs({ "corsec", "smuggler", false }) do
		local spies = P.spyAllStarts()
		local player = P.pilot("burke", { squadron = squadron })

		P.talk("burke", player)
		P.talk("burke", player)

		lu.assertNil(H.getQuestStatus(player, P.ADMIRALS.burke.sideKey), tostring(squadron) .. ": Rebel key")
		lu.assertNil(H.getQuestStatus(player, P.ADMIRALS.burke.otherKey), tostring(squadron) .. ": Imperial key")
		lu.assertNil(H.getQuestStatus(player, "master_rebel_1:attempted"), tostring(squadron) .. ": :attempted")
		lu.assertEquals(player.bankCredits or 0, 0, tostring(squadron) .. ": credits")
		lu.assertEquals(P.standing("burke", player), 0, tostring(squadron) .. ": standing")

		for g, calls in pairs(spies) do
			lu.assertEquals(#calls, 0, tostring(squadron) .. ": " .. g .. " startQuest calls")
		end
	end
end
