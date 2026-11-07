-- Brother Vrovel: grants of the four story missions, the failure walks and their re-grants.
-- Spec: .claude/work/vortex-tier2-vrovel/01-spec.md (AC-5; Conversation flow 1 (V12 to V23), 3 (table H) and 4; FV-7; D-8; I-5).
--
-- A start screen sets <mission>:attempted and starts the chain head through SpaceHelpers:startSpaceQuestChain (refused while any member is active).
-- The failure screens (mN_failed) start nothing: SWG re-grants on the accept reply (mN_retry, FV-7). Heads are spied (the call is recorded, the
-- original is not run) except where a test says "real": then the pilot sits in a ship in the quest zone and the real head activates its journal entry.

local lu = require("luaunit")
local H = require("harness")
local V = require("vortex_tier2_data")
local CS = require("harness.client_strings")

V.loadConversation()

local function setUp()
	H.reset()
	V.requireConversation(lu)
end

local ZONE = { "space_lok", "space_yavin4", "space_yavin4", "space_dantooine" }

-- the screens of each mission, from V.START_SCREENS, sorted
local function startScreens(n)
	local out = {}

	for screen, mission in pairs(V.START_SCREENS) do
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
		out[n] = H.getQuestStatus(player, V.STATUS[n] .. ":attempted")
	end

	return out
end

TestVrovelStarts = {}

TestVrovelStarts.setUp = setUp

-- AC-5, I-5: every start screen of mission n sets :attempted and starts its head, once, with the pilot (the quest heads are spied)
for n = 1, 4 do
	for _, screen in ipairs(startScreens(n)) do
		TestVrovelStarts["test_" .. screen .. "_sets_attempted_and_starts_the_head_of_mission_" .. n] = function()
			local player = V.pilot({ missions = n - 1, t2 = n })
			local spies = V.spyStarts()
			local t = V.drive(player, screen)

			lu.assertEquals(V.ids(t), { screen }, "the screen")
			lu.assertTrue(t[1].stop, screen .. " ends the conversation")
			lu.assertEquals(V.startedCount(spies), { [V.HEADS[n]] = 1 }, screen .. ": quests started")
			lu.assertEquals(spies[V.HEADS[n]][1].args[1], player, "startQuest got the pilot")
			lu.assertEquals(H.getQuestStatus(player, V.STATUS[n] .. ":attempted"), "1", screen .. ": :attempted of mission " .. n)
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end

		-- AC-5: the real head runs (the pilot sits in a ship in the quest zone)
		TestVrovelStarts["test_" .. screen .. "_makes_the_real_head_quest_active"] = function()
			local player = V.pilot({ missions = n - 1, t2 = n, inShip = true, zone = ZONE[n] })
			local q = V.quest(V.HEADS[n])

			q:start()
			V.drive(player, screen)
			lu.assertEquals(V.state(player, V.HEADS[n]), "active", V.HEADS[n] .. ": journal entry after " .. screen)
			lu.assertEquals(H.getQuestStatus(player, V.STATUS[n] .. ":attempted"), "1", ":attempted")
		end

		-- AC-5, I-5: a start while the chain is active changes nothing (the run is not restarted)
		TestVrovelStarts["test_" .. screen .. "_while_the_chain_is_active_starts_nothing_and_changes_nothing"] = function()
			local player = V.pilot({ missions = n - 1, t2 = n, state = "active" })
			local spies = V.spyStarts()

			V.drive(player, screen)
			lu.assertEquals(V.startedCount(spies), {}, screen .. ": quests started while the head is active")
			lu.assertEquals(V.state(player, V.HEADS[n]), "active", "the journal entry stays")
			lu.assertEquals(H.getQuestStatus(player, V.STATUS[n] .. ":attempted"), "1", ":attempted stays")
		end
	end
end

-- AC-5: a start screen sets only its own :attempted key
function TestVrovelStarts:test_a_start_screen_sets_only_its_own_attempted_key()
	local player = V.pilot({ missions = 1, t2 = 2 })

	V.spyStarts()
	V.drive(player, "m2_accept")
	lu.assertEquals(attemptedKeys(player), { "1", "1", nil, nil }, "attempted keys after m2_accept (mission 1 was paid before)")
end

-- AC-5: a second start screen in the same walk does not start a second run (the first run is active)
function TestVrovelStarts:test_a_second_start_screen_in_the_same_walk_does_not_start_a_second_run()
	local player = V.pilot({ missions = 2, t2 = 3 })
	local spies = V.spyStarts()

	V.drive(player, "m3_accept_yes_sir")
	-- the real head would now be active in the journal
	V.setState(player, V.R3, "active")
	V.drive(player, "m3_accept_wartime")
	V.drive(player, "m3_retry")
	lu.assertEquals(#spies[V.R3], 1, "recovery_vortex_mission_3: startQuest calls over three start screens")
end

-- AC-5, I-5: every screen that is not a start or duty screen starts nothing and sets no :attempted key
function TestVrovelStarts:test_no_other_screen_starts_a_quest_or_sets_an_attempted_key()
	for _, row in ipairs(V.SCREENS) do
		if V.START_SCREENS[row.id] == nil and V.DUTY_SCREENS[row.id] == nil then
			H.reset()

			local player = V.pilot({ missions = 1, t2 = 2, xp = 999999, privileged = true })
			local spies = V.spyStarts()

			V.drive(player, row.id)
			lu.assertEquals(V.startedCount(spies), {}, "screen '" .. row.id .. "': quests started")
			lu.assertEquals(attemptedKeys(player), { "1" }, "screen '" .. row.id .. "': attempted keys (only mission 1, paid before)")
		end
	end
end

-- AC-5, I-5: opening the conversation (the gate screens) starts nothing, whatever the pilot's state
function TestVrovelStarts:test_opening_the_conversation_starts_nothing_for_any_mission_state()
	for n = 1, 4 do
		for _, state in ipairs({ "failed", "won", "none" }) do
			H.reset()

			local player = V.pilot({ missions = n - 1, t2 = n, state = state ~= "none" and state or nil })
			local spies = V.spyStarts()

			V.talk(player)
			lu.assertEquals(V.startedCount(spies), {}, "mission " .. n .. " " .. state .. ": quests started by opening the conversation")
		end
	end
end

---------------------------------------------------------------------------------------------
-- The failure walks and re-grants (FV-7)
---------------------------------------------------------------------------------------------

TestVrovelFailures = {}

TestVrovelFailures.setUp = setUp

-- { mission, failed screen, the replies to the retry screen, retry screen, the replies to a decline screen, decline screen }
local WALKS = {
	{ n = 1, failed = "m1_failed", accept = { "s_f4f48ced" }, retry = "m1_retry", decline = { "s_d5273669" }, declineScreen = "m1_hurry_back" },
	{ n = 2, failed = "m2_failed", accept = { "s_900f01d1", "s_b17504ae", "s_24084ede" }, retry = "m2_retry", decline = { "s_900f01d1", "s_b17504ae", "s_304f442f" }, declineScreen = "m2_recover" },
	{ n = 3, failed = "m3_failed", accept = { "s_e3516195" }, retry = "m3_retry", decline = { "s_5d243499" }, declineScreen = "m3_coward" },
	{ n = 4, failed = "m4_failed", accept = { "s_6a35a7eb" }, retry = "m4_retry", decline = { "s_1d85385d" }, declineScreen = "m4_failed_nonsense" },
}

for _, w in ipairs(WALKS) do
	-- AC-5, FV-7: the failure screen itself starts nothing
	TestVrovelFailures["test_" .. w.failed .. "_starts_nothing_on_display"] = function()
		local player = V.pilot({ missions = w.n - 1, t2 = w.n, state = "failed" })
		local spies = V.spyStarts()
		local t = V.talk(player)

		lu.assertEquals(t[1].id, w.failed, "first screen")
		lu.assertEquals(V.startedCount(spies), {}, w.failed .. ": quests started on display")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-5, FV-7: the accept route re-grants (a start on the retry screen)
	TestVrovelFailures["test_the_accept_route_of_" .. w.failed .. "_regrants_on_" .. w.retry] = function()
		local player = V.pilot({ missions = w.n - 1, t2 = w.n, state = "failed" })
		local spies = V.spyStarts()
		local t = V.talk(player, w.accept)

		lu.assertEquals(t[#t].id, w.retry, "the walk ends on the retry screen")
		lu.assertEquals(V.startedCount(spies), { [V.HEADS[w.n]] = 1 }, "quests started")
		lu.assertEquals(H.getQuestStatus(player, V.STATUS[w.n] .. ":attempted"), "1", ":attempted")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-5, FV-7: the decline route starts nothing
	TestVrovelFailures["test_the_decline_route_of_" .. w.failed .. "_starts_nothing"] = function()
		local player = V.pilot({ missions = w.n - 1, t2 = w.n, state = "failed" })
		local spies = V.spyStarts()
		local t = V.talk(player, w.decline)

		lu.assertEquals(t[#t].id, w.declineScreen, "the walk ends on the decline screen")
		lu.assertEquals(V.startedCount(spies), {}, "quests started")
		lu.assertEquals(V.firstScreen(player), w.failed, "the next talk shows the failure screen again")
	end

	-- AC-5: with the real head the mission runs after the retry and the next talk is on_mission
	TestVrovelFailures["test_the_retry_of_" .. w.failed .. "_makes_the_real_head_active"] = function()
		local player = V.pilot({ missions = w.n - 1, t2 = w.n, state = "failed", inShip = true, zone = ZONE[w.n] })

		V.quest(V.HEADS[w.n]):start()
		V.talk(player, w.accept)
		lu.assertEquals(V.state(player, V.HEADS[w.n]), "active", V.HEADS[w.n] .. ": journal entry after the retry")
		lu.assertEquals(V.firstScreen(player), "on_mission", "the next talk")
	end

	-- AC-5: a mission aborted from the datapad opens the failure screen (abort is failure)
	TestVrovelFailures["test_mission_" .. w.n .. "_aborted_from_the_datapad_opens_" .. w.failed] = function()
		local player = V.pilot({ missions = w.n - 1, t2 = w.n })
		local head = V.quest(V.HEADS[w.n])

		H.setQuestStatus(player, V.STATUS[w.n] .. ":attempted", "1")
		V.setState(player, V.HEADS[w.n], "active")
		lu.assertEquals(V.firstScreen(player), "on_mission", "while it flies")
		head:abortQuest(player)
		lu.assertEquals(V.state(player, V.HEADS[w.n]), "none", "the abort ends the run")
		lu.assertEquals(V.firstScreen(player), w.failed, "after the abort")
	end
end

-- AC-5, FV-7: mission 1 counts any of its three quests: the inspect or the surprise attack failed after the escort was done
function TestVrovelFailures:test_mission_1_with_the_inspect_or_the_surprise_attack_lost_opens_the_failure_screen()
	local inspectLost = V.pilot({ missions = 0, t2 = 1 })

	H.setQuestStatus(inspectLost, "vortex_mission_1:attempted", "1")
	V.setState(inspectLost, V.E1, "complete")
	lu.assertEquals(V.firstScreen(inspectLost), "m1_failed", "escort complete, inspect failed")

	local attackLost = V.pilot({ missions = 0, t2 = 1 })

	H.setQuestStatus(attackLost, "vortex_mission_1:attempted", "1")
	V.setState(attackLost, V.E1, "complete")
	V.setState(attackLost, V.I1, "complete")
	lu.assertEquals(V.firstScreen(attackLost), "m1_failed", "escort and inspect complete, the surprise attack lost")
end

-- AC-5, FV-7: the retry of mission 1 restarts the chain from its head (the chain's old journal entries are cleared by startSpaceQuestChain)
function TestVrovelFailures:test_the_mission_1_retry_clears_the_old_chain_entries_and_starts_the_head()
	local player = V.pilot({ missions = 0, t2 = 1, inShip = true, zone = "space_lok" })

	H.setQuestStatus(player, "vortex_mission_1:attempted", "1")
	V.setState(player, V.E1, "complete")
	V.setState(player, V.I1, "complete")
	V.quest(V.E1):start()
	V.talk(player, { "s_f4f48ced" })
	lu.assertEquals(V.state(player, V.E1), "active", "the head is running again")
	lu.assertEquals(V.state(player, V.I1), "none", "the inspect entry is cleared")
	lu.assertEquals(V.state(player, V.S1), "none", "the surprise attack entry is cleared")
end

-- AC-5: the offer screens and the briefings do not grant; only the accept screens do (the offer walk to the first accept)
function TestVrovelStarts:test_the_offer_walks_grant_only_on_the_accept_screen()
	local walks = {
		{ n = 1, choices = { "s_77213dae", "s_92aee067" }, accept = "m1_accept" },
		{ n = 2, choices = { "s_b91de387", "s_432be150", "s_b74318f4" }, accept = "m2_accept" },
		{ n = 3, choices = { "s_3aa053cf", "s_ca3670fd" }, accept = "m3_accept_wartime" },
		{ n = 4, choices = { "s_9793aadf", "s_8c4fba26", "s_9dbb5a9a", "s_16d870fe" }, accept = "m4_accept" },
	}

	for _, w in ipairs(walks) do
		H.reset()

		local player = V.pilot({ missions = w.n - 1, t2 = w.n })
		local spies = V.spyStarts()
		local t = V.talk(player, w.choices)

		lu.assertEquals(t[#t].id, w.accept, "mission " .. w.n .. ": the offer walk ends on the accept screen")
		lu.assertEquals(V.startedCount(spies), { [V.HEADS[w.n]] = 1 }, "mission " .. w.n .. ": started once, on the accept screen only")
		lu.assertEquals(#t >= 3, true, "mission " .. w.n .. ": a walk through the briefing")
	end
end
