-- Major Eker: grants of the four story missions, the failure walks and their re-grants.
-- Spec: .claude/work/crimson-phoenix-tier2-eker-convo/01-spec.md (AC-5; Conversation flow 1 (E13 to E24), 3 (table H) and 4; FE-7; D-8; I-5).
--
-- A start screen sets <mission>:attempted and starts the chain head through SpaceHelpers:startSpaceQuestChain (refused while any member is active).
-- The failure screens (mN_failed) start nothing: SWG re-grants on the reply (mN_retry, FE-7). Heads are spied (the call is recorded, the original is not
-- run) except where a test says "real": then the pilot sits in a ship in the quest zone and the real head activates its journal entry.

local lu = require("luaunit")
local H = require("harness")
local E = require("crimson_tier2_data")
local CS = require("harness.client_strings")

E.loadConversation()

local function setUp()
	H.reset()
	E.requireConversation(lu)
end

-- a pilot Eker has handed in (flag "2") unless the test says otherwise
local function P(o)
	local opts = { graduated = "2" }

	for k, v in pairs(o or {}) do
		opts[k] = v
	end

	return E.pilot(opts)
end

-- the zone of each head (E13, I14, I15, E16)
local ZONE = { "space_yavin4", "space_yavin4", "space_lok", "space_lok" }

-- the screens of mission n, from E.START_SCREENS, sorted
local function startScreens(n)
	local out = {}

	for screen, mission in pairs(E.START_SCREENS) do
		if mission == n then
			out[#out + 1] = screen
		end
	end

	table.sort(out)
	return out
end

local function attemptedKeys(player)
	local out = {}

	for n = 1, 4 do
		out[n] = H.getQuestStatus(player, E.STATUS[n] .. ":attempted")
	end

	return out
end

TestEkerStarts = {}

TestEkerStarts.setUp = setUp

-- AC-5, I-5: every start screen of mission n sets :attempted and starts its head, once, with the pilot (the quest heads are spied)
for n = 1, 4 do
	for _, screen in ipairs(startScreens(n)) do
		TestEkerStarts["test_" .. screen .. "_sets_attempted_and_starts_the_head_of_mission_" .. n] = function()
			local player = P({ missions = n - 1, t2 = n })
			local spies = E.spyStarts()
			local t = E.drive(player, screen)

			lu.assertEquals(E.ids(t), { screen }, "the screen")
			lu.assertEquals(E.startedCount(spies), { [E.HEADS[n]] = 1 }, screen .. ": quests started")
			lu.assertEquals(spies[E.HEADS[n]][1].args[1], player, "startQuest got the pilot")
			lu.assertEquals(H.getQuestStatus(player, E.STATUS[n] .. ":attempted"), "1", screen .. ": :attempted of mission " .. n)
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end

		-- AC-5: the real head runs (the pilot sits in a ship in the quest zone)
		TestEkerStarts["test_" .. screen .. "_makes_the_real_head_quest_active"] = function()
			local player = P({ missions = n - 1, t2 = n, inShip = true, zone = ZONE[n] })

			E.quest(E.HEADS[n]):start()
			E.drive(player, screen)
			lu.assertEquals(E.state(player, E.HEADS[n]), "active", E.HEADS[n] .. ": journal entry after " .. screen)
			lu.assertEquals(H.getQuestStatus(player, E.STATUS[n] .. ":attempted"), "1", ":attempted")
		end

		-- AC-5, I-5: a start while the chain is active changes nothing (the run is not restarted)
		TestEkerStarts["test_" .. screen .. "_while_the_chain_is_active_starts_nothing_and_changes_nothing"] = function()
			local player = P({ missions = n - 1, t2 = n, state = "active" })
			local spies = E.spyStarts()

			E.drive(player, screen)
			lu.assertEquals(E.startedCount(spies), {}, screen .. ": quests started while the head is active")
			lu.assertEquals(E.state(player, E.HEADS[n]), "active", "the journal entry stays")
			lu.assertEquals(H.getQuestStatus(player, E.STATUS[n] .. ":attempted"), "1", ":attempted stays")
		end
	end
end

-- AC-5: the start screens are the 22 of the spec
function TestEkerStarts:test_there_are_22_start_screens_and_each_ends_the_conversation()
	local n = 0

	for screen in pairs(E.START_SCREENS) do
		n = n + 1

		if not screen:find("^m1_accept_opinion$") then
			local row = E.screenRow(screen)

			lu.assertNotNil(row, "Appendix A row of " .. screen)
			lu.assertTrue(row.stop, screen .. " ends the conversation")
		end
	end

	lu.assertEquals(n, 22, "start screens")
end

-- AC-5: a start screen sets only its own :attempted key
function TestEkerStarts:test_a_start_screen_sets_only_its_own_attempted_key()
	local player = P({ missions = 1, t2 = 2 })

	E.spyStarts()
	E.drive(player, "m2_accept_closing")
	lu.assertEquals(attemptedKeys(player), { "1", "1", nil, nil }, "attempted keys after m2_accept_closing (mission 1 was paid before)")
end

-- AC-5: a second start screen in the same walk does not start a second run: m1_accept_opinion grants and is followed by m1_accept_right
function TestEkerStarts:test_a_second_start_screen_in_the_same_walk_does_not_start_a_second_run()
	local player = P({ missions = 0, t2 = 1 })
	local spies = E.spyStarts()
	local t = E.talk(player, {
		"s_468ab4d3", "s_313aff7d", "s_2e17432d",
		-- the first start screen (m1_accept_opinion) was shown: the head is running now
		function(p) E.setState(p, E.E13, "active") end,
		"s_5494c458",
	})

	lu.assertEquals(t[#t].id, "m1_accept_right", "the walk reaches the second start screen")
	lu.assertEquals(t[#t - 1].id, "m1_accept_opinion", "after the first start screen")
	lu.assertEquals(#spies[E.E13], 1, "escort_yavin_rebel_13: startQuest calls over two start screens")
	lu.assertEquals(H.getQuestStatus(player, E.STATUS[1] .. ":attempted"), "1", ":attempted")
end

-- AC-5, D-8: m1_accept_opinion grants and offers two replies (SWG keeps the grant on this line); the first reply starts nothing
function TestEkerStarts:test_m1_accept_opinion_grants_and_offers_its_two_replies()
	local player = P({ missions = 0, t2 = 1 })
	local spies = E.spyStarts()
	local t = E.drive(player, "m1_accept_opinion")

	lu.assertFalse(t[1].stop, "m1_accept_opinion waits for a reply")
	lu.assertEquals(E.optionSids(t[1]), { "s_e23e884f", "s_5494c458" }, "its two replies")
	lu.assertEquals(E.startedCount(spies), { [E.E13] = 1 }, "started on display")

	local ready = E.drive(P({ missions = 0, t2 = 1 }), "m1_accept_opinion", { "s_e23e884f" })

	lu.assertEquals(E.ids(ready), { "m1_accept_opinion", "m1_ready_to_work" }, "the first reply")
	lu.assertTrue(ready[2].stop, "m1_ready_to_work ends")
end

-- AC-5, I-5: every screen that is not a start or duty screen starts nothing and sets no :attempted key
function TestEkerStarts:test_no_other_screen_starts_a_quest_or_sets_an_attempted_key()
	for _, row in ipairs(E.SCREENS) do
		if E.START_SCREENS[row.id] == nil and E.DUTY_SCREENS[row.id] == nil then
			H.reset()

			local player = P({ missions = 1, t2 = 2, xp = 999999, privileged = true })
			local spies = E.spyStarts()

			E.drive(player, row.id)
			lu.assertEquals(E.startedCount(spies), {}, "screen '" .. row.id .. "': quests started")
			lu.assertEquals(attemptedKeys(player), { "1" }, "screen '" .. row.id .. "': attempted keys (only mission 1, paid before)")
		end
	end
end

-- AC-5, I-5: opening the conversation (the gate screens) starts nothing, whatever the pilot's state
function TestEkerStarts:test_opening_the_conversation_starts_nothing_for_any_mission_state()
	for n = 1, 4 do
		for _, state in ipairs({ "failed", "won", "none" }) do
			H.reset()

			local player = P({ missions = n - 1, t2 = n, state = state ~= "none" and state or nil })
			local spies = E.spyStarts()

			E.talk(player)
			lu.assertEquals(E.startedCount(spies), {}, "mission " .. n .. " " .. state .. ": quests started by opening the conversation")
		end
	end
end

-- AC-5: the offer walks grant only on their accept screens; { mission, replies from the offer, the accept screen reached }
local OFFERS = {
	{ n = 1, choices = { "s_468ab4d3", "s_313aff7d", "s_f685a04e" }, accept = "m1_accept_dismissed" },
	{ n = 1, choices = { "s_468ab4d3", "s_1591adc2", "s_8e9d0848" }, accept = "m1_accept_uploading" },
	{ n = 1, choices = { "s_468ab4d3", "s_2dec7766", "s_9b43a7ee" }, accept = "m1_accept_uploading" },
	{ n = 1, choices = { "s_e58651c5", "s_97f7a201", "s_d945a469" }, accept = "m1_accept_priority" },
	{ n = 1, choices = { "s_7065e138", "s_5e7c5f7b", "s_ca4d37ba" }, accept = "m1_accept_immediately" },
	{ n = 2, choices = { "s_b1df084d", "s_d5609495", "s_8bdbd90b" }, accept = "m2_accept_closing" },
	{ n = 2, choices = { "s_b1df084d", "s_d5609495", "s_62b1a1d0" }, accept = "m2_accept_droid" },
	{ n = 3, choices = { "s_ae785ffa", "s_841d27db", "s_3de0965c", "s_71bb443b", "s_6aacd1f1", "s_38f14bb8", "s_2588496a", "s_a99ad4e8" }, accept = "m3_accept" },
	{ n = 3, choices = { "s_ae785ffa", "s_841d27db", "s_a0412756", "s_7b4382cf", "s_cd0a60d4", "s_47003e68", "s_851cc47", "s_a99ad4e8" }, accept = "m3_accept" },
	{ n = 4, choices = { "s_6673b556", "s_14bcd839", "s_32146025", "s_d24a2285", "s_c3c8f385" }, accept = "m4_accept_trust" },
	{ n = 4, choices = { "s_6673b556", "s_3d419bc4", "s_b2e9d505", "s_bb25f9e7" }, accept = "m4_accept_go_back" },
	{ n = 4, choices = { "s_4431cbae", "s_f930a587", "s_39acc227", "s_6c251948" }, accept = "m4_accept_smuggle" },
}

for i, w in ipairs(OFFERS) do
	TestEkerStarts["test_the_offer_walk_" .. i .. "_of_mission_" .. w.n .. "_grants_only_on_" .. w.accept] = function()
		local player = P({ missions = w.n - 1, t2 = w.n })
		local spies = E.spyStarts()
		local t = E.talk(player, w.choices)

		lu.assertEquals(t[1].id, E.MISSIONS[w.n].offer, "mission " .. w.n .. ": the offer")
		lu.assertEquals(t[#t].id, w.accept, "the offer walk ends on the accept screen")
		lu.assertEquals(#t, #w.choices + 1, "one screen per reply")
		lu.assertEquals(E.startedCount(spies), { [E.HEADS[w.n]] = 1 }, "mission " .. w.n .. ": started once, on the accept screen only")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-5: the refusals in the offers start nothing
function TestEkerStarts:test_the_refusals_in_the_offers_start_nothing()
	local cases = {
		{ n = 1, choices = { "s_38e4c8a3" }, last = "m1_paperwork" },
		{ n = 2, choices = { "s_12a5eddf" }, last = "m2_beauty_sleep" },
		{ n = 2, choices = { "s_b1df084d", "s_564211e6" }, last = "m2_joke" },
		{ n = 3, choices = { "s_ae785ffa", "s_841d27db", "s_3de0965c", "s_71bb443b", "s_6aacd1f1", "s_38f14bb8", "s_ee790f5c" }, last = "m3_arrest" },
		{ n = 4, choices = { "s_47a389f6" }, last = "m4_double_time" },
		{ n = 4, choices = { "s_4431cbae", "s_62f0f943" }, last = "m4_see_you_around" },
	}

	for _, c in ipairs(cases) do
		H.reset()

		local player = P({ missions = c.n - 1, t2 = c.n })
		local spies = E.spyStarts()
		local t = E.talk(player, c.choices)

		lu.assertEquals(t[#t].id, c.last, "mission " .. c.n .. ": the refusal screen")
		lu.assertTrue(t[#t].stop, c.last .. " ends")
		lu.assertEquals(E.startedCount(spies), {}, c.last .. ": quests started")
		lu.assertEquals(E.firstScreen(player), E.MISSIONS[c.n].offer, "the next talk offers the mission again")
	end
end

---------------------------------------------------------------------------------------------
-- The failure walks and re-grants (FE-7)
---------------------------------------------------------------------------------------------

TestEkerFailures = {}

TestEkerFailures.setUp = setUp

-- per mission: the failure screen and its routes { replies, the screen reached, whether it grants again }
local FAILS = {
	{ n = 1, failed = "m1_failed", routes = {
		{ choices = { "s_d9c145dd" }, last = "m1_retry_now", starts = true },
		{ choices = { "s_b585598c", "s_252b3bf5" }, last = "m1_retry_knew", starts = true },
		{ choices = { "s_b585598c", "s_b601ca9f" }, last = "m1_not_beg", starts = false },
	} },
	{ n = 2, failed = "m2_failed", routes = {
		{ choices = { "s_d8db54f6" }, last = "m2_retry", starts = true },
		{ choices = { "s_591601b8", "s_4ca03ddb" }, last = "m2_retry_rules", starts = true },
		{ choices = { "s_b130ff0a" }, last = "m2_failed_repairs", starts = false },
	} },
	{ n = 3, failed = "m3_failed", routes = {
		{ choices = { "s_e0651b79" }, last = "m3_retry", starts = true },
		{ choices = { "s_b130ff0a" }, last = "m3_failed_worry", starts = false },
	} },
	{ n = 4, failed = "m4_failed", routes = {
		{ choices = { "s_80d8485c" }, last = "m4_retry", starts = true },
		{ choices = { "s_78bae101" }, last = "m4_failed_dismissed", starts = false },
	} },
}

for _, f in ipairs(FAILS) do
	-- AC-5, FE-7: the failure screen itself starts nothing
	TestEkerFailures["test_" .. f.failed .. "_starts_nothing_on_display"] = function()
		local player = P({ missions = f.n - 1, t2 = f.n, state = "failed" })
		local spies = E.spyStarts()
		local t = E.talk(player)

		lu.assertEquals(t[1].id, f.failed, "first screen")
		lu.assertEquals(E.startedCount(spies), {}, f.failed .. ": quests started on display")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	for k, r in ipairs(f.routes) do
		TestEkerFailures["test_the_route_" .. k .. "_of_" .. f.failed .. "_" .. (r.starts and "regrants_on_" or "starts_nothing_on_") .. r.last] = function()
			local player = P({ missions = f.n - 1, t2 = f.n, state = "failed" })
			local spies = E.spyStarts()
			local t = E.talk(player, r.choices)

			lu.assertEquals(t[#t].id, r.last, "the walk ends on " .. r.last)
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")

			if r.starts then
				lu.assertEquals(E.startedCount(spies), { [E.HEADS[f.n]] = 1 }, "quests started")
				lu.assertEquals(H.getQuestStatus(player, E.STATUS[f.n] .. ":attempted"), "1", ":attempted")
			else
				lu.assertEquals(E.startedCount(spies), {}, "quests started")
				lu.assertEquals(E.firstScreen(player), f.failed, "the next talk shows the failure screen again")
			end
		end
	end

	-- AC-5: with the real head the mission runs after the retry and the next talk is on_mission
	TestEkerFailures["test_the_retry_of_" .. f.failed .. "_makes_the_real_head_active"] = function()
		local player = P({ missions = f.n - 1, t2 = f.n, state = "failed", inShip = true, zone = ZONE[f.n] })

		E.quest(E.HEADS[f.n]):start()
		E.talk(player, f.routes[1].choices)
		lu.assertEquals(E.state(player, E.HEADS[f.n]), "active", E.HEADS[f.n] .. ": journal entry after the retry")
		lu.assertEquals(E.firstScreen(player), "on_mission", "the next talk")
	end

	-- AC-5: a mission aborted from the datapad opens the failure screen (abort is failure)
	TestEkerFailures["test_mission_" .. f.n .. "_aborted_from_the_datapad_opens_" .. f.failed] = function()
		local player = P({ missions = f.n - 1, t2 = f.n })
		local head = E.quest(E.HEADS[f.n])

		H.setQuestStatus(player, E.STATUS[f.n] .. ":attempted", "1")
		E.setState(player, E.HEADS[f.n], "active")
		lu.assertEquals(E.firstScreen(player), "on_mission", "while it flies")
		head:abortQuest(player)
		lu.assertEquals(E.state(player, E.HEADS[f.n]), "none", "the abort ends the run")
		lu.assertEquals(E.firstScreen(player), f.failed, "after the abort")
	end
end

-- AC-5: mission 3 counts either member: the inspect or the surprise attack failed
function TestEkerFailures:test_mission_3_with_the_inspect_failed_or_the_surprise_attack_failed_opens_the_failure_screen()
	local inspectLost = P({ missions = 2, t2 = 3 })

	H.setQuestStatus(inspectLost, E.STATUS[3] .. ":attempted", "1")
	lu.assertEquals(E.firstScreen(inspectLost), "m3_failed", "the inspect failed (nothing complete)")

	local attackLost = P({ missions = 2, t2 = 3 })

	H.setQuestStatus(attackLost, E.STATUS[3] .. ":attempted", "1")
	E.setState(attackLost, E.I15, "complete")
	lu.assertEquals(E.firstScreen(attackLost), "m3_failed", "the inspect complete (the silent split completion), the surprise attack lost: not a win")
end

-- AC-5: the retry of mission 3 clears the old chain entries and starts the head again
function TestEkerFailures:test_the_mission_3_retry_clears_the_old_chain_entries_and_starts_the_head()
	local player = P({ missions = 2, t2 = 3, inShip = true, zone = "space_lok" })

	H.setQuestStatus(player, E.STATUS[3] .. ":attempted", "1")
	E.setState(player, E.I15, "complete")
	E.quest(E.I15):start()
	E.talk(player, { "s_e0651b79" })
	lu.assertEquals(E.state(player, E.I15), "active", "the head is running again")
	lu.assertEquals(E.state(player, E.S15), "none", "the surprise attack entry is cleared")
end
