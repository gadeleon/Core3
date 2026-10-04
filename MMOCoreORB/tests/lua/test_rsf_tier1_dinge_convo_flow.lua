-- Dinge (RSF tier 1) on SWG's story dialogue: what the conversation does. Offers that grant at the end of the SWG chain, the failure
-- screens and where they re-grant (D-12), payments on the reward screens (D-4), the running-mission and directions screens, signup and
-- the ship grant, the duty menu, the tier-done line, and the handler/template agreement (dynamic part). Training is in test_rsf_tier1_dinge_training_*.lua;
-- the rows and tests below that touched it were superseded by .claude/work/rsf-tier1-dinge-training/01-spec.md (D-12 routing, groups S and T).
-- Spec: .claude/work/rsf-tier1-dinge-convo/01-spec.md (AC-3 .. AC-10, invariants I-4, I-5, Conversation flow C1-C17).
-- Appendix A (rsf_tier1_dinge_convo_data.lua) is the answer key for screens, options and actions.
-- space-convo-client-strings-dinge (.claude/work/space-convo-client-strings-dinge/01-spec.md, AC-3 .. AC-6, AC-10; Appendix A) re-pins 17 tests of this file
-- to the pre-NGE flow through D.current(): the has-ship sign-up goes yes_ship -> signup_offer (no signup_ready_ship / signup_ship_later), the mission 3 and 4
-- replies are client lines, the duty decline ends on not_ready, first_training lists the four choice replies, and the template has 64 screens.
-- Fake limits: the harness does not model NPC animations (they are template fields, checked in the template test) and
-- `grantStarterShip` is a recorded no-op (it does not change `certifiedShip`).

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local D = require("rsf_tier1_dinge_convo_data")

T.load()

local tr = T.TRAINERS.dinge
local P = D.PREFIX

local ORIGINAL_CHAIN = SpaceHelpers.startSpaceQuestChain

local M1, S1 = "patrol_naboo_privateer_1", "destroy_surpriseattack_naboo_privateer_1"
local M2 = "destroy_naboo_privateer_2"
local M3, E3 = "patrol_naboo_privateer_3", "escort_naboo_privateer_3"
local M4 = "assassinate_naboo_privateer_tier1_4a"
local DUTY6, DUTY7 = "destroy_duty_naboo_privateer_6", "escort_duty_naboo_privateer_7"
local SKILLS_01 = { "pilot_neutral_droid_01", "pilot_neutral_procedures_01", "pilot_neutral_starships_01", "pilot_neutral_weapons_01" }

local function rowsById()
	local byId = {}

	for _, row in ipairs(D.current()) do
		byId[row.id] = row
	end

	return byId
end

local ROWS = rowsById()

local function ids(transcript)
	local out = {}

	for i, step in ipairs(transcript) do
		out[i] = step.id
	end

	return out
end

local function texts(options)
	local out = {}

	for i, o in ipairs(options) do
		out[i] = o.text
	end

	return out
end

local function sids(list)
	local out = {}

	for i, sid in ipairs(list) do
		out[i] = P .. sid
	end

	return out
end

local function rowSids(row)
	local out = {}

	for i, o in ipairs(row.options) do
		out[i] = P .. o[1]
	end

	return out
end

local function handler() return H.expectGlobal(H.conversationTemplateTable(tr.template).luaClassHandler, "Dinge conversation handler") end

-- Runs runScreenHandlers for one screen, the way the observer does for a screen the player reached
local function enterScreen(player, id, npc)
	local tmpl = H.conversationTemplate(tr.template)
	local pScreen = LuaConversationTemplate(tmpl):getScreen(id)

	lu.assertNotNil(pScreen, "screen '" .. id .. "' is in " .. tr.template)
	return handler():runScreenHandlers(tmpl, player, npc or H.newNpc({}), 0, pScreen)
end

-- What getInitialScreen alone returns (the engine calls runScreenHandlers on it afterwards; this does not)
local function initialScreenId(player)
	local pScreen = handler():getInitialScreen(player, H.newNpc({}), H.conversationTemplate(tr.template))

	lu.assertNotNil(pScreen, "getInitialScreen returned no screen")
	return LuaConversationScreen(pScreen):getScreenID()
end

-- Records startSpaceQuestChain calls and still runs the real one. Restored by restore() (called from tearDown).
local function tapChains()
	local calls = {}

	SpaceHelpers.startSpaceQuestChain = function(self, ...)
		calls[#calls + 1] = { args = table.pack(...) }
		return ORIGINAL_CHAIN(self, ...)
	end

	return calls
end

local function restore() SpaceHelpers.startSpaceQuestChain = ORIGINAL_CHAIN end

local function attempted(player, n) return H.getQuestStatus(player, D.KEYS[n] .. ":attempted") end
local function rewarded(player, n) return H.getQuestStatus(player, D.KEYS[n] .. ":reward") end

local function headIds(chains)
	local out = {}

	for i, c in ipairs(chains) do
		out[i] = c.args[3]
	end

	return out
end

-- Every path (no screen twice) from screen `startId` to a screen that ends the conversation, as { ids, choices (0-based) }
local function paths(startId)
	local out = {}

	local function walk(id, seen, idList, choices)
		local row = ROWS[id]

		lu.assertNotNil(row, "appendix row " .. id)

		if row.stop then
			out[#out + 1] = { ids = idList, choices = choices }
			return
		end

		for i, o in ipairs(row.options) do
			if not seen[o[2]] then
				local nextSeen, nextIds, nextChoices = {}, {}, {}

				for k in pairs(seen) do nextSeen[k] = true end
				for k, v in ipairs(idList) do nextIds[k] = v end
				for k, v in ipairs(choices) do nextChoices[k] = v end

				nextSeen[o[2]] = true
				nextIds[#nextIds + 1] = o[2]
				nextChoices[#nextChoices + 1] = i - 1
				walk(o[2], nextSeen, nextIds, nextChoices)
			end
		end
	end

	walk(startId, { [startId] = true }, { startId }, {})
	return out
end

local function concat(...)
	local out = {}

	for _, list in ipairs({ ... }) do
		for _, v in ipairs(list) do
			out[#out + 1] = v
		end
	end

	return out
end

-- A conversation that follows `choices`, with a snapshot of the mission n state after every screen that offers options.
-- Returns transcript, snapshots (snapshots[k] = state right after screen k was entered), calls (startSpaceQuestChain), rec (rewards).
local function walkWithSnapshots(player, choices, n)
	local calls = tapChains()
	local rec = T.spyRewards()
	local snaps = {}
	local list = {}

	local function snap()
		snaps[#snaps + 1] = { attempted = attempted(player, n), state = T.state(player, D.HEADS[n]), chainCalls = #calls, rewards = #rec.rewards }
	end

	for _, c in ipairs(choices) do
		list[#list + 1] = snap
		list[#list + 1] = c
	end

	local transcript = T.converse(tr, player, list)

	return transcript, snaps, calls, rec
end

local NONE = { attempted = nil, state = "none", chainCalls = 0, rewards = 0 }

-- The mission-n player in front of the offer screen (missions before n won and paid, n never attempted)
local function fresh(n) return T.player(tr, n, { attempted = false }) end

-- Mission n won, not yet paid
local function wonUnpaid(n) return T.player(tr, n, { complete = tr.chains[n] }) end

-- A pilot in a state where the failure screen of mission n is shown: attempted and not won
local function failedPlayer(n, variant)
	if variant == "head_won_child_failed" then
		return T.player(tr, n, { complete = { tr.chains[n][1] } })
	end

	return T.player(tr, n, {})
end

---------------------------------------------------------------------------------------------
-- Conversation flow C1-C17: first screens (also AC-3 .. AC-6, AC-8, AC-9 entry points)
---------------------------------------------------------------------------------------------

TestDingeFirstScreens = {}

function TestDingeFirstScreens:setUp() H.reset() end
function TestDingeFirstScreens:tearDown() restore() end

local function noShip(player) player.certifiedShip = false return player end

local FIRST_SCREENS = {
	-- C1 (unchanged)
	{ "c1_rebel_pilot", function() return H.newPlayer({ pilot = "rebel" }) end, "rebel_pilot" },
	{ "c1_imperial_pilot", function() return H.newPlayer({ pilot = "imperial" }) end, "imperial_pilot" },
	{ "c1_neutral_pilot_of_another_squadron", function() local p = T.player(tr, 1, {}) p.ghost:setSquadronType(0) return p end, "non_rsf_pilot" },
	-- C2, C3
	{ "c2_pilot_without_the_neutral_skill", function() return H.newPlayer({ name = "Ace" }) end, "recruitment" },
	{ "c3_enlisted_pilot_without_a_ship_and_mission_1_not_running", function() return noShip(T.player(tr, 1, {})) end, "no_ship" },
	-- C4
	{ "c4_mission_2_running", function() return T.player(tr, 2, { active = { M2 } }) end, "has_mission" },
	{ "c4_mission_3_head_running", function() return T.player(tr, 3, { active = { M3 } }) end, "has_mission" },
	{ "c4_mission_3_escort_running", function() return T.player(tr, 3, { complete = { M3 }, active = { E3 } }) end, "has_mission" },
	{ "c4_mission_4_running", function() return T.player(tr, 4, { active = { M4 } }) end, "has_mission" },
	{ "c4_destroy_duty_running", function() return T.player(tr, 4, { win = { 1, 2, 3, 4 }, active = { DUTY6 } }) end, "has_mission" },
	{ "c4_escort_duty_running", function() return T.player(tr, 4, { win = { 1, 2, 3, 4 }, active = { DUTY7 } }) end, "has_mission" },
	-- C5
	{ "c5_all_four_tier_1_skills", function() return T.player(tr, 1, { skills = SKILLS_01 }) end, "completed_tier1" },
	-- C6, C7 (setup: M4 won and paid, D-12 of rsf-tier1-dinge-training; the screens are unchanged)
	{ "c6_tier_1_skill_and_xp_to_train", function() return T.player(tr, 1, { win = { 1, 2, 3, 4 }, skills = { SKILLS_01[1] }, experience = { space_combat_general = 7500 } }) end, "more_training" },
	{ "c7_tier_1_skill_and_no_xp", function() return T.player(tr, 4, { win = { 1, 2, 3, 4 }, skills = { SKILLS_01[1] } }) end, "duty_missions" },
	-- C8, C9
	{ "c8_mission_4_won_and_paid", function() return T.player(tr, 4, { win = { 1, 2, 3, 4 } }) end, "first_training" },
	{ "c9_mission_4_won_not_paid", function() return wonUnpaid(4) end, "mission4_reward" },
	-- C10
	{ "c10_mission_4_attempted_and_not_won", function() return T.player(tr, 4, {}) end, "mission4_failed" },
	{ "c10_mission_4_never_attempted", function() return fresh(4) end, "mission4_offer" },
	-- C11
	{ "c11_mission_3_won_not_paid", function() return wonUnpaid(3) end, "mission3_reward" },
	-- C12
	{ "c12_mission_3_attempted_and_not_won", function() return T.player(tr, 3, {}) end, "mission3_failed" },
	{ "c12_mission_3_head_won_child_failed", function() return failedPlayer(3, "head_won_child_failed") end, "mission3_failed" },
	{ "c12_mission_3_never_attempted", function() return fresh(3) end, "mission3_offer" },
	-- C13
	{ "c13_mission_2_won_not_paid", function() return wonUnpaid(2) end, "mission2_reward" },
	-- C14
	{ "c14_mission_2_attempted_and_not_won", function() return T.player(tr, 2, {}) end, "mission2_failed" },
	{ "c14_mission_2_never_attempted", function() return fresh(2) end, "mission2_offer" },
	-- C15
	{ "c15_mission_1_won_not_paid", function() return wonUnpaid(1) end, "mission1_reward" },
	-- C16
	{ "c16_mission_1_head_running", function() return T.player(tr, 1, { active = { M1 } }) end, "mission1_active" },
	{ "c16_mission_1_surprise_attack_running", function() return T.player(tr, 1, { complete = { M1 }, active = { S1 } }) end, "mission1_active" },
	-- C17
	{ "c17_mission_1_attempted_and_not_won", function() return T.player(tr, 1, {}) end, "mission1_failed" },
	{ "c17_mission_1_head_won_child_failed", function() return failedPlayer(1, "head_won_child_failed") end, "mission1_failed" },
	{ "c17_mission_1_never_attempted", function() return fresh(1) end, "mission1_offer" },
}

for _, row in ipairs(FIRST_SCREENS) do
	-- AC-3 .. AC-9
	TestDingeFirstScreens["test_" .. row[1] .. "_starts_on_" .. row[3]] = function()
		lu.assertEquals(initialScreenId(row[2]()), row[3], row[1] .. ": getInitialScreen")
		lu.assertEquals(T.converse(tr, row[2]())[1].id, row[3], row[1] .. ": first screen of the conversation")
	end

	-- AC-5, AC-10, D-4, I-4: choosing the first screen pays, starts and writes nothing
	TestDingeFirstScreens["test_" .. row[1] .. "_get_initial_screen_pays_starts_and_sets_nothing"] = function()
		local player = row[2]()
		local rec = T.spyAllQuests()
		local chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")
		local before = {}

		for n = 1, 4 do
			before[n] = { attempted(player, n), rewarded(player, n) }
		end

		initialScreenId(player)

		lu.assertEquals(rec.rewards, {}, row[1] .. ": rewardPlayer calls")
		lu.assertEquals(rec.starts, {}, row[1] .. ": startQuest calls")
		lu.assertEquals(#chains, 0, row[1] .. ": startSpaceQuestChain calls")

		for n = 1, 4 do
			lu.assertEquals({ attempted(player, n), rewarded(player, n) }, before[n], row[1] .. ": :attempted / :reward of mission " .. n)
		end
	end
end

-- AC-6: has_mission is Dinge's point_away line and ends the conversation
function TestDingeFirstScreens:test_has_mission_is_one_ending_screen_showing_s_61036267()
	local transcript = T.converse(tr, T.player(tr, 2, { active = { M2 } }))

	lu.assertEquals(ids(transcript), { "has_mission" }, "screens")
	lu.assertTrue(transcript[1].stop, "has_mission ends the conversation")
	lu.assertEquals(transcript[1].options, {}, "has_mission: options")
end

---------------------------------------------------------------------------------------------
-- AC-3: the offers grant at the end of the SWG chain
---------------------------------------------------------------------------------------------

TestDingeOffers = {}

function TestDingeOffers:setUp() H.reset() end
function TestDingeOffers:tearDown() restore() end

local function pathName(p) return table.concat(p.ids, "_") end

for n = 1, 4 do
	for _, p in ipairs(paths(D.OFFER[n])) do
		-- AC-3
		TestDingeOffers["test_mission_" .. n .. "_offer_path_" .. pathName(p) .. "_sets_attempted_and_starts_the_head_only_on_its_last_screen"] = function()
			local player = fresh(n)
			local transcript, snaps, calls, rec = walkWithSnapshots(player, p.choices, n)

			lu.assertEquals(ids(transcript), p.ids, "mission " .. n .. ": screens walked")
			lu.assertTrue(transcript[#transcript].stop, "mission " .. n .. ": " .. p.ids[#p.ids] .. " ends the conversation")

			for k = 1, #p.choices do
				lu.assertEquals(snaps[k], NONE, "mission " .. n .. ": nothing granted, set or paid after " .. p.ids[k])
			end

			lu.assertEquals(attempted(player, n), "1", D.KEYS[n] .. ":attempted after " .. p.ids[#p.ids])
			lu.assertEquals(T.state(player, D.HEADS[n]), "active", D.HEADS[n] .. " after " .. p.ids[#p.ids])
			lu.assertEquals(headIds(calls), { D.HEADS[n] }, "startSpaceQuestChain calls over the whole path")
			lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
		end
	end

	-- AC-3: the entry line of the offer and its answers are SWG's
	TestDingeOffers["test_mission_" .. n .. "_offer_is_the_first_screen_and_shows_its_appendix_options"] = function()
		local transcript = T.converse(tr, fresh(n))

		lu.assertEquals(transcript[1].id, D.OFFER[n], "first screen")
		lu.assertEquals(texts(transcript[1].options), rowSids(ROWS[D.OFFER[n]]), "options of " .. D.OFFER[n])
		lu.assertFalse(transcript[1].stop, D.OFFER[n] .. " does not end the conversation")
	end
end

-- AC-3: the loop through mission1_after_assignments, then each accept screen
function TestDingeOffers:test_mission_1_loop_through_after_assignments_twice_still_grants_only_on_the_accept_screen()
	local player = fresh(1)
	local transcript, snaps, calls = walkWithSnapshots(player, { 2, 2, 2, 0 }, 1)

	lu.assertEquals(ids(transcript), { "mission1_offer", "mission1_after_assignments", "mission1_after_assignments", "mission1_after_assignments", "mission1_accept" }, "screens")

	for k = 1, 4 do
		lu.assertEquals(snaps[k], NONE, "mission 1: nothing granted after screen " .. k)
	end

	lu.assertEquals(headIds(calls), { M1 }, "startSpaceQuestChain calls")
	lu.assertEquals(attempted(player, 1), "1", "naboo_privateer_1:attempted")
end

-- AC-3: the boast branch reaches both boast accept screens
function TestDingeOffers:test_mission_1_boast_accept_screens_both_start_mission_1()
	for i, id in ipairs({ "mission1_boast_accept1", "mission1_boast_accept2" }) do
		H.reset()

		local player = fresh(1)
		local transcript = T.converse(tr, player, { 1, i - 1 })

		lu.assertEquals(ids(transcript), { "mission1_offer", "mission1_boast", id }, "screens for the boast answer " .. i)
		lu.assertEquals(T.state(player, M1), "active", id .. ": " .. M1)
		lu.assertEquals(attempted(player, 1), "1", id .. ": naboo_privateer_1:attempted")
	end
end

-- AC-3, AC-7: the signup entries into the same M1 options grant at the end too
for name, setup in pairs({
	no_ship = {
		player = function() return H.newPlayer({ name = "Ace", certifiedShip = false }) end,
		prefix = { "s_d70dba34", "s_9817b9bb", "s_b9b27823", "s_36a4e374" },
		prefixIds = { "recruitment", "yes_enlist", "signup_no_ship", "ready_first_assignment", "signup_offer" },
		offer = "signup_offer",
	},
	has_ship = {
		player = function() return H.newPlayer({ name = "Ace", certifiedShip = true }) end,
		prefix = { "s_d70dba34", "s_5c522568", "s_36a4e374" }, -- "Yes, I am." leads to signup_offer (F2 D-1)
		prefixIds = { "recruitment", "yes_enlist", "yes_ship", "signup_offer" },
		offer = "signup_offer",
	},
}) do
	for _, p in ipairs(paths(setup.offer)) do
		-- AC-3, AC-7
		TestDingeOffers["test_signup_" .. name .. "_path_" .. pathName(p) .. "_starts_mission_1_only_on_its_last_screen"] = function()
			local player = setup.player()
			local allIds = {}

			for _, id in ipairs(setup.prefixIds) do
				allIds[#allIds + 1] = id
			end

			for k = 2, #p.ids do
				allIds[#allIds + 1] = p.ids[k]
			end

			local transcript, snaps, calls, rec = walkWithSnapshots(player, concat(setup.prefix, p.choices), 1)

			lu.assertEquals(ids(transcript), allIds, "signup (" .. name .. "): screens walked")
			lu.assertTrue(transcript[#transcript].stop, p.ids[#p.ids] .. " ends the conversation")

			for k = 1, #snaps do
				lu.assertEquals(snaps[k], NONE, "signup (" .. name .. "): nothing started or set after " .. allIds[k])
			end

			lu.assertEquals(headIds(calls), { M1 }, "startSpaceQuestChain calls over the whole signup")
			lu.assertEquals(attempted(player, 1), "1", "naboo_privateer_1:attempted")
			lu.assertEquals(T.state(player, M1), "active", M1)
			lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
		end
	end
end

-- AC-3, I-3: the %TU name is filled on the mission 2 briefing lines
function TestDingeOffers:test_mission_2_brief_and_accept_fill_the_pilot_name()
	local transcript = T.converse(tr, fresh(2), { 0, 0 })

	lu.assertEquals(ids(transcript), { "mission2_offer", "mission2_brief", "mission2_accept" }, "screens")
	lu.assertEquals(transcript[2].params.TU, "Ace", "mission2_brief: %TU")
	lu.assertEquals(transcript[3].params.TU, "Ace", "mission2_accept: %TU")
end

---------------------------------------------------------------------------------------------
-- AC-4: failures (D-12)
---------------------------------------------------------------------------------------------

TestDingeFailures = {}

function TestDingeFailures:setUp() H.reset() end
function TestDingeFailures:tearDown() restore() end

for n = 1, 4 do
	local failed = D.FAILED[n][1]
	local replies = D.FAILED[n][2]
	local variants = { "no_entry" }

	if #tr.chains[n] > 1 then
		variants[#variants + 1] = "head_won_child_failed"
	end

	for _, variant in ipairs(variants) do
		if n == 2 then
			-- AC-4: M2 re-grants on its failure line as soon as it is shown, and ends
			TestDingeFailures["test_mission_2_failure_line_regrants_mission_2_as_soon_as_it_is_shown_" .. variant] = function()
				local player = failedPlayer(n, variant)
				local calls = tapChains()
				local rec = T.spyRewards()
				local transcript = T.converse(tr, player)

				lu.assertEquals(ids(transcript), { "mission2_failed" }, "screens")
				lu.assertTrue(transcript[1].stop, "mission2_failed ends the conversation")
				lu.assertEquals(transcript[1].options, {}, "mission2_failed: options")
				lu.assertEquals(headIds(calls), { M2 }, "startSpaceQuestChain calls")
				lu.assertEquals(T.state(player, M2), "active", M2)
				lu.assertEquals(attempted(player, 2), "1", "naboo_privateer_2:attempted")
				lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
				lu.assertNil(rewarded(player, 2), "naboo_privateer_2:reward")
			end
		else
			-- AC-4: the failure line itself grants nothing for M1, M3, M4 (the window may be closed here)
			TestDingeFailures["test_mission_" .. n .. "_failure_line_alone_grants_nothing_" .. variant] = function()
				local player = failedPlayer(n, variant)
				local before = T.journalSnapshot(player)
				local calls = tapChains()
				local rec = T.spyAllQuests()
				local transcript = T.converse(tr, player)

				lu.assertEquals(ids(transcript), { failed }, "screens")
				lu.assertFalse(transcript[1].stop, failed .. " does not end the conversation")
				lu.assertEquals(texts(transcript[1].options), rowSids(ROWS[failed]), failed .. ": reply options")
				lu.assertEquals(#calls, 0, "startSpaceQuestChain calls after the failure line only")
				lu.assertEquals(rec.starts, {}, "startQuest calls")
				lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
				lu.assertEquals(T.journalSnapshot(player), before, "journal after the failure line only")
				lu.assertEquals(attempted(player, n), "1", D.KEYS[n] .. ":attempted (set earlier, untouched)")
			end

			-- AC-4: every reply grants the mission (the player cannot decline), and ends
			for i, retry in ipairs(replies) do
				TestDingeFailures["test_mission_" .. n .. "_reply_" .. i .. "_to_the_failure_line_goes_to_" .. retry .. "_and_regrants_it_" .. variant] = function()
					local player = failedPlayer(n, variant)
					local calls = tapChains()
					local rec = T.spyRewards()
					local transcript = T.converse(tr, player, { i - 1 })

					lu.assertEquals(ids(transcript), { failed, retry }, "screens")
					lu.assertTrue(transcript[2].stop, retry .. " ends the conversation")
					lu.assertEquals(headIds(calls), { D.HEADS[n] }, "startSpaceQuestChain calls")
					lu.assertEquals(attempted(player, n), "1", D.KEYS[n] .. ":attempted")
					lu.assertEquals(T.state(player, D.HEADS[n]), "active", D.HEADS[n])

					for k = 2, #tr.chains[n] do
						lu.assertEquals(T.state(player, tr.chains[n][k]), "none", tr.chains[n][k] .. " (the head is the only active chain member)")
					end

					lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
					lu.assertNil(rewarded(player, n), D.KEYS[n] .. ":reward (nothing was paid)")
				end
			end
		end
	end

	-- AC-4: a pilot who has not attempted the mission sees the offer, not the failure line, in the same state
	TestDingeFailures["test_mission_" .. n .. "_not_won_and_never_attempted_shows_the_offer_not_the_failure_line"] = function()
		lu.assertEquals(T.converse(tr, T.player(tr, n, { attempted = false }))[1].id, D.OFFER[n], "first screen")
	end
end

-- AC-4: the failure options are SWG's
function TestDingeFailures:test_the_failure_lines_offer_the_swg_replies_in_order()
	for _, n in ipairs({ 1, 3, 4 }) do
		H.reset()

		local failed = D.FAILED[n][1]
		local transcript = T.converse(tr, T.player(tr, n, {}))

		lu.assertEquals(texts(transcript[1].options), rowSids(ROWS[failed]), failed .. ": options")
		lu.assertEquals(#transcript[1].options, #D.FAILED[n][2], failed .. ": one option per reply screen")
	end
end

-- AC-4: attempted is set when a mission starts (any start screen) and cleared by the squadron reset
local function seededVeteran()
	local player = T.player(tr, 4, { win = { 1, 2, 3, 4 } })

	for n = 1, 4 do
		lu.assertEquals(attempted(player, n), "1", "setup: " .. D.KEYS[n] .. ":attempted")
	end

	return player
end

-- AC-4
function TestDingeFailures:test_reset_dinge_quests_clears_the_four_attempted_keys()
	local player = seededVeteran()

	RsfSquadronScreenplay:resetDingeQuests(player)

	for n = 1, 4 do
		lu.assertNil(attempted(player, n), D.KEYS[n] .. ":attempted after resetDingeQuests")
	end
end

-- AC-4, F-3: the reward keys are deliberately not cleared
function TestDingeFailures:test_reset_dinge_quests_keeps_the_reward_keys()
	local player = seededVeteran()

	RsfSquadronScreenplay:resetDingeQuests(player)

	for n = 1, 4 do
		lu.assertEquals(rewarded(player, n), "1", D.KEYS[n] .. ":reward after resetDingeQuests (F-3)")
	end
end

-- AC-4: surrendering the pilot profession goes through the same reset
function TestDingeFailures:test_surrender_pilot_clears_the_four_attempted_keys()
	local player = seededVeteran()

	player.ghost:setSquadronType(RSF_SQUADRON)
	SpaceHelpers:surrenderPilot(player)

	for n = 1, 4 do
		lu.assertNil(attempted(player, n), D.KEYS[n] .. ":attempted after surrenderPilot")
	end
end

-- AC-4: the reset does not clear another trainer's keys
function TestDingeFailures:test_reset_dinge_quests_leaves_other_status_keys_alone()
	local player = seededVeteran()

	H.setQuestStatus(player, "naboo_privateer_tier2_1a:attempted", 1)
	RsfSquadronScreenplay:resetDingeQuests(player)
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_tier2_1a:attempted"), "1", "Kaydine's mission 1 :attempted")
end

-- AC-4: a rejoined pilot sees the mission 1 offer
function TestDingeFailures:test_a_pilot_who_rejoins_after_the_reset_sees_the_mission_1_offer_not_the_failure_line()
	local player = seededVeteran()

	RsfSquadronScreenplay:resetDingeQuests(player)

	local rec = T.spyRewards()
	local transcript = T.converse(tr, player)

	lu.assertEquals(transcript[1].id, "mission1_offer", "first screen after the reset")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls after the reset")
end

-- Migration / R-3: no :attempted key means the offer, whatever the quest log says
function TestDingeFailures:test_a_pilot_who_failed_before_the_flag_existed_sees_the_offer_with_nothing_changed()
	for n = 1, 4 do
		H.reset()

		local player = T.player(tr, n, { attempted = false })

		lu.assertNil(attempted(player, n), "setup: no :attempted key for mission " .. n)
		lu.assertEquals(T.converse(tr, player)[1].id, D.OFFER[n], "mission " .. n .. ": first screen")
		lu.assertNil(attempted(player, n), "mission " .. n .. ": showing the offer sets no :attempted key")
	end
end

-- AC-4, AC-3: the flag is per mission
function TestDingeFailures:test_starting_mission_2_does_not_set_the_attempted_key_of_another_mission()
	local player = fresh(2)

	T.converse(tr, player, { 0, 0 })
	lu.assertEquals(attempted(player, 2), "1", "naboo_privateer_2:attempted")
	lu.assertEquals(attempted(player, 3), nil, "naboo_privateer_3:attempted")
	lu.assertEquals(attempted(player, 4), nil, "naboo_privateer_tier1_4a:attempted")
end

---------------------------------------------------------------------------------------------
-- AC-5: rewards on the reward screens (D-4)
---------------------------------------------------------------------------------------------

TestDingeRewards = {}

function TestDingeRewards:setUp() H.reset() end
function TestDingeRewards:tearDown() restore() end

for n = 1, 4 do
	local screen = "mission" .. n .. "_reward"
	local nextScreen = n < 4 and D.OFFER[n + 1] or "first_training"

	-- AC-5: only the conversation's first screen pays
	TestDingeRewards["test_get_initial_screen_alone_pays_nothing_for_" .. screen] = function()
		local player = wonUnpaid(n)
		local rec = T.spyAllQuests()

		lu.assertEquals(initialScreenId(player), screen, "getInitialScreen")
		lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
		lu.assertNil(rewarded(player, n), D.KEYS[n] .. ":reward")
	end

	-- AC-5: the reward screen pays once, after :reward is set
	TestDingeRewards["test_" .. screen .. "_pays_the_head_exactly_once_after_setting_the_reward_key"] = function()
		local player = wonUnpaid(n)
		local calls = H.spyOn(_G[D.HEADS[n]], "rewardPlayer", function(self, pPlayer) return H.getQuestStatus(pPlayer, D.KEYS[n] .. ":reward") end)
		local others = {}

		for _, name in ipairs(H.questGlobals()) do
			if name ~= D.HEADS[n] then
				H.spyOn(_G[name], "rewardPlayer", function() others[#others + 1] = name end)
			end
		end

		local transcript = T.converse(tr, player)

		lu.assertEquals(transcript[1].id, screen, "first screen")
		lu.assertEquals(#calls, 1, D.HEADS[n] .. ":rewardPlayer calls")
		lu.assertEquals(calls[1].snapshot, "1", D.KEYS[n] .. ":reward at the time rewardPlayer ran")
		lu.assertEquals(calls[1].args[1], player, "rewardPlayer is called for the pilot")
		lu.assertEquals(others, {}, "rewardPlayer calls on other quests")
		lu.assertEquals(rewarded(player, n), "1", D.KEYS[n] .. ":reward")
	end

	if n ~= 3 then
		-- AC-5: M1, M2 and M4 end on the reward line
		TestDingeRewards["test_" .. screen .. "_ends_the_conversation_with_no_options"] = function()
			local transcript = T.converse(tr, wonUnpaid(n))

			lu.assertEquals(ids(transcript), { screen }, "screens")
			lu.assertTrue(transcript[1].stop, screen .. " ends the conversation")
			lu.assertEquals(transcript[1].options, {}, screen .. ": options")
		end
	end

	-- AC-5: a second conversation shows the next state's first screen and pays nothing
	TestDingeRewards["test_after_" .. screen .. "_the_next_conversation_starts_on_" .. nextScreen .. "_and_pays_nothing"] = function()
		local player = wonUnpaid(n)

		T.converse(tr, player)

		local rec = T.spyRewards()
		local transcript = T.converse(tr, player)

		lu.assertEquals(transcript[1].id, nextScreen, "first screen of the second conversation")
		lu.assertEquals(rec.rewards, {}, "rewardPlayer calls in the second conversation")
		lu.assertEquals(rewarded(player, n), "1", D.KEYS[n] .. ":reward")
	end

	-- AC-5: a pilot whose reward key is already set is not paid again
	TestDingeRewards["test_a_pilot_already_paid_for_mission_" .. n .. "_is_not_paid_again"] = function()
		local player = wonUnpaid(n)

		H.setQuestStatus(player, D.KEYS[n] .. ":reward", 1)

		local rec = T.spyRewards()
		local transcript = T.converse(tr, player)

		lu.assertEquals(transcript[1].id, nextScreen, "first screen")
		lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
	end
end

-- AC-5: M3's reward line has two replies that both lead to the bandolier line, then to the mission 4 offer
for i, sid in ipairs({ "s_c4682ea6", "s_1c8bddbb" }) do
	TestDingeRewards["test_mission_3_reward_reply_" .. sid .. "_leads_to_the_bandolier_line_and_the_mission_4_offer_without_paying_again"] = function()
		local player = wonUnpaid(3)
		local rec = T.spyRewards()
		local calls = tapChains()
		local transcript = T.converse(tr, player, { sid, 0, 0 })

		lu.assertEquals(ids(transcript), { "mission3_reward", "mission3_reward_bandolier", "mission4_offer", "mission4_accept" }, "screens")
		lu.assertEquals(texts(transcript[1].options), sids({ "s_c4682ea6", "s_1c8bddbb" }), "mission3_reward: options")
		lu.assertEquals(texts(transcript[2].options), sids({ "s_3f49e786" }), "mission3_reward_bandolier: options")
		lu.assertEquals(rec.rewards, { M3 }, "rewardPlayer calls over the whole conversation")
		lu.assertEquals(headIds(calls), { M4 }, "startSpaceQuestChain calls (only the final accept screen)")
		lu.assertEquals(attempted(player, 4), "1", "naboo_privateer_tier1_4a:attempted")
	end
end

-- AC-5: the bandolier line itself starts nothing and pays nothing
function TestDingeRewards:test_the_bandolier_line_and_the_mission_4_offer_start_and_pay_nothing()
	local player = wonUnpaid(3)
	local calls = tapChains()
	local transcript, snaps = walkWithSnapshots(player, { 0, 0 }, 4)

	lu.assertEquals(ids(transcript), { "mission3_reward", "mission3_reward_bandolier", "mission4_offer" }, "screens")
	lu.assertEquals(#calls, 0, "startSpaceQuestChain calls up to the offer")
	lu.assertEquals(snaps[2].chainCalls, 0, "after the bandolier line")
	lu.assertEquals(snaps[2].rewards, 1, "rewards paid by then (mission 3 only)")
	lu.assertNil(attempted(player, 4), "naboo_privateer_tier1_4a:attempted before the accept screen")
end

-- AC-5 (superseded by rsf-tier1-dinge-training D-12, then by space-convo-client-strings-dinge AC-7): M4's reward line is followed by first training, which
-- lists the four pre-NGE choice replies
function TestDingeRewards:test_mission_4_reward_is_followed_by_first_training_in_the_next_conversation_with_the_four_choice_replies()
	local player = wonUnpaid(4)

	T.converse(tr, player)

	local transcript = T.converse(tr, player)

	lu.assertEquals(transcript[1].id, "first_training", "first screen")
	lu.assertEquals(texts(transcript[1].options), sids({ "s_e94f494b", "s_939b6844", "s_ac00d21e", "s_1726d8a5" }), "first_training: options")
end

---------------------------------------------------------------------------------------------
-- AC-6: mission running
---------------------------------------------------------------------------------------------

TestDingeMissionRunning = {}

function TestDingeMissionRunning:setUp() H.reset() end
function TestDingeMissionRunning:tearDown() restore() end

local DIRECTIONS = { "mission1_where_go", "mission1_get_back", "mission1_where_ship" }
local RUNNING = {
	{ "head", function() return T.player(tr, 1, { active = { M1 } }) end },
	{ "surprise_attack", function() return T.player(tr, 1, { complete = { M1 }, active = { S1 } }) end },
}

for _, state in ipairs(RUNNING) do
	-- AC-6
	TestDingeMissionRunning["test_mission_1_" .. state[1] .. "_running_shows_the_directions_options"] = function()
		local transcript = T.converse(tr, state[2]())

		lu.assertEquals(transcript[1].id, "mission1_active", "first screen")
		lu.assertEquals(texts(transcript[1].options), rowSids(ROWS.mission1_active), "options of mission1_active")
		lu.assertFalse(transcript[1].stop, "mission1_active does not end the conversation")
	end

	-- AC-6: each directions option twice, each leads to the same three options, nothing is started or paid
	for i, target in ipairs(DIRECTIONS) do
		TestDingeMissionRunning["test_mission_1_" .. state[1] .. "_running_option_" .. i .. "_twice_stays_on_" .. target .. "_and_starts_and_pays_nothing"] = function()
			local player = state[2]()
			local calls = tapChains()
			local rec = T.spyAllQuests()
			local before = T.journalSnapshot(player)
			local transcript = T.converse(tr, player, { i - 1, i - 1, i - 1 })

			lu.assertEquals(ids(transcript), { "mission1_active", target, target, target }, "screens")

			for k, step in ipairs(transcript) do
				lu.assertFalse(step.stop, "step " .. k .. " (" .. step.id .. ") ends the conversation")
				lu.assertEquals(texts(step.options), rowSids(ROWS.mission1_active), "step " .. k .. " (" .. step.id .. "): options")
			end

			lu.assertEquals(#calls, 0, "startSpaceQuestChain calls")
			lu.assertEquals(rec.starts, {}, "startQuest calls")
			lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
			lu.assertEquals(T.journalSnapshot(player), before, "journal")

			for n = 2, 4 do
				lu.assertNil(attempted(player, n), D.KEYS[n] .. ":attempted")
			end
		end
	end

	-- AC-6: every directions screen leads to every directions screen
	TestDingeMissionRunning["test_mission_1_" .. state[1] .. "_running_every_directions_screen_links_to_all_three"] = function()
		local player = state[2]()
		local transcript = T.converse(tr, player, { 0, 1, 2, 0, 2, 1 })

		lu.assertEquals(ids(transcript), { "mission1_active", "mission1_where_go", "mission1_get_back", "mission1_where_ship", "mission1_where_go", "mission1_where_ship", "mission1_get_back" }, "screens")
	end
end

-- AC-6
function TestDingeMissionRunning:test_a_running_mission_1_does_not_regrant_even_when_attempted_is_set()
	local player = T.player(tr, 1, { active = { M1 }, attempted = true })
	local calls = tapChains()

	T.converse(tr, player, { 0 })
	lu.assertEquals(#calls, 0, "startSpaceQuestChain calls")
end

---------------------------------------------------------------------------------------------
-- AC-7: signup and ship
---------------------------------------------------------------------------------------------

TestDingeSignup = {}

function TestDingeSignup:setUp() H.reset() end
function TestDingeSignup:tearDown() restore() end

local function newcomer(hasShip) return H.newPlayer({ name = "Ace", certifiedShip = hasShip }) end

-- AC-7
function TestDingeSignup:test_a_pilot_with_no_neutral_skill_sees_recruitment_with_its_two_answers()
	local transcript = T.converse(tr, newcomer(true))

	lu.assertEquals(transcript[1].id, "recruitment", "first screen")
	lu.assertEquals(texts(transcript[1].options), rowSids(ROWS.recruitment), "options of recruitment")
	lu.assertEquals(transcript[1].options[1].link, "yes_enlist", "recruitment: option 1 link")
	lu.assertEquals(transcript[1].options[2].link, "no_enlist", "recruitment: option 2 link")
end

-- AC-7
function TestDingeSignup:test_s_4c695dbd_ends_on_no_enlist_and_grants_nothing()
	local player = newcomer(true)
	local calls = tapChains()
	local transcript = T.converse(tr, player, { "s_4c695dbd" })

	lu.assertEquals(ids(transcript), { "recruitment", "no_enlist" }, "screens")
	lu.assertTrue(transcript[2].stop, "no_enlist ends the conversation")
	lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, "awardSkill calls")
	lu.assertFalse(player:hasSkill("pilot_neutral_novice"), "pilot_neutral_novice")
	lu.assertEquals(player.ghost:getSquadronType(), 0, "squadron type")
	lu.assertEquals(player.ghost:getPilotTier(), 0, "pilot tier")
	lu.assertEquals(#calls, 0, "startSpaceQuestChain calls")
end

-- AC-7
function TestDingeSignup:test_s_d70dba34_enlists_the_pilot_in_the_rsf_at_tier_1()
	local player = newcomer(true)
	local transcript = T.converse(tr, player, { "s_d70dba34" })

	lu.assertEquals(ids(transcript), { "recruitment", "yes_enlist" }, "screens")
	lu.assertTrue(player:hasSkill("pilot_neutral_novice"), "novice box")
	lu.assertEquals(player.ghost:getSquadronType(), RSF_SQUADRON, "squadron type")
	lu.assertEquals(player.ghost:getPilotTier(), 1, "pilot tier")
end

-- AC-7: D-8, the player's nod stays
function TestDingeSignup:test_enlisting_still_plays_the_players_nod_head_once_and_nothing_else()
	local player = newcomer(true)

	T.converse(tr, player, { "s_d70dba34" })
	lu.assertEquals(player.animations, { "nod_head_once" }, "player animations")
end

-- AC-7, E-2
function TestDingeSignup:test_a_pilot_without_a_certified_ship_gets_exactly_the_s_9817b9bb_option_to_signup_no_ship()
	local transcript = T.converse(tr, newcomer(false), { "s_d70dba34" })

	lu.assertEquals(transcript[2].id, "yes_enlist", "second screen")
	lu.assertEquals(texts(transcript[2].options), { P .. "s_9817b9bb" }, "yes_enlist: options")
	lu.assertEquals(transcript[2].options[1].link, "signup_no_ship", "yes_enlist: link")
end

-- AC-7, E-2
function TestDingeSignup:test_a_pilot_with_a_certified_ship_gets_exactly_the_s_5c522568_option_to_yes_ship()
	local transcript = T.converse(tr, newcomer(true), { "s_d70dba34" })

	lu.assertEquals(transcript[2].id, "yes_enlist", "second screen")
	lu.assertEquals(texts(transcript[2].options), { P .. "s_5c522568" }, "yes_enlist: options")
	lu.assertEquals(transcript[2].options[1].link, "yes_ship", "yes_enlist: link")
end

-- AC-7, E-2: the added option is per conversation, not stuck in the template
function TestDingeSignup:test_the_signup_option_is_not_left_in_the_template()
	T.converse(tr, newcomer(false), { "s_d70dba34" })
	T.converse(tr, newcomer(true), { "s_d70dba34" })

	for _, s in ipairs(H.conversationTemplateTable(tr.template).screens) do
		if s.id == "yes_enlist" then
			lu.assertEquals(s.options, {}, "yes_enlist template options after two conversations")
		end
	end
end

-- AC-7
function TestDingeSignup:test_without_a_ship_the_path_grants_the_ship_on_signup_no_ship_and_starts_mission_1_on_mission1_accept()
	local player = newcomer(false)
	local steps = {}
	local calls = tapChains()
	local transcript = T.converse(tr, player, {
		"s_d70dba34", function() steps[1] = #H.Engine.callsTo("grantStarterShip") end,
		"s_9817b9bb", function() steps[2] = #H.Engine.callsTo("grantStarterShip") end,
		"s_b9b27823", "s_36a4e374", "s_1db37a0f",
	})

	lu.assertEquals(ids(transcript), { "recruitment", "yes_enlist", "signup_no_ship", "ready_first_assignment", "signup_offer", "mission1_accept" }, "screens")
	lu.assertEquals(steps, { 0, 1 }, "grantStarterShip calls after yes_enlist, after signup_no_ship")
	lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 1, "grantStarterShip calls over the whole signup")
	lu.assertEquals(H.Engine.callsTo("grantStarterShip")[1][2], "neutral", "grantStarterShip faction")
	lu.assertEquals(T.state(player, M1), "active", M1)
	lu.assertEquals(headIds(calls), { M1 }, "startSpaceQuestChain calls")
	lu.assertTrue(transcript[6].stop, "mission1_accept ends the conversation")
end

-- AC-7
function TestDingeSignup:test_signup_no_ship_shows_s_e3245432_with_the_single_option_s_b9b27823_to_ready_first_assignment()
	local transcript = T.converse(tr, newcomer(false), { "s_d70dba34", "s_9817b9bb" })

	lu.assertEquals(transcript[3].id, "signup_no_ship", "third screen")
	lu.assertEquals(texts(transcript[3].options), { P .. "s_b9b27823" }, "signup_no_ship: options")
	lu.assertEquals(transcript[3].options[1].link, "ready_first_assignment", "signup_no_ship: link")
end

-- AC-7
function TestDingeSignup:test_s_68660d24_ends_on_signup_not_ready_and_starts_nothing()
	local player = newcomer(false)
	local calls = tapChains()
	local transcript = T.converse(tr, player, { "s_d70dba34", "s_9817b9bb", "s_b9b27823", "s_68660d24" })

	lu.assertEquals(ids(transcript), { "recruitment", "yes_enlist", "signup_no_ship", "ready_first_assignment", "signup_not_ready" }, "screens")
	lu.assertTrue(transcript[5].stop, "signup_not_ready ends the conversation")
	lu.assertEquals(#calls, 0, "startSpaceQuestChain calls")
	lu.assertEquals(T.state(player, M1), "none", M1)
	lu.assertNil(attempted(player, 1), "naboo_privateer_1:attempted")
end

-- AC-7
function TestDingeSignup:test_with_a_ship_the_path_grants_no_ship_and_starts_mission_1_on_the_offer()
	local player = newcomer(true)
	local calls = tapChains()
	local transcript = T.converse(tr, player, { "s_d70dba34", "s_5c522568", "s_36a4e374", "s_1db37a0f" })

	lu.assertEquals(ids(transcript), { "recruitment", "yes_enlist", "yes_ship", "signup_offer", "mission1_accept" }, "screens")
	lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "grantStarterShip calls")
	lu.assertEquals(T.state(player, M1), "active", M1)
	lu.assertEquals(headIds(calls), { M1 }, "startSpaceQuestChain calls")
	lu.assertEquals(attempted(player, 1), "1", "naboo_privateer_1:attempted")
end

-- AC-7; space-convo-client-strings-dinge AC-3: "I need to take care of some things first." (was the NGE s_34 / signup_ship_later)
function TestDingeSignup:test_with_a_ship_s_68660d24_ends_on_signup_not_ready_and_starts_nothing()
	local player = newcomer(true)
	local calls = tapChains()
	local transcript = T.converse(tr, player, { "s_d70dba34", "s_5c522568", "s_68660d24" })

	lu.assertEquals(ids(transcript), { "recruitment", "yes_enlist", "yes_ship", "signup_not_ready" }, "screens")
	lu.assertEquals(transcript[4].text, P .. "s_f5f16210", "signup_not_ready: NPC line")
	lu.assertTrue(transcript[4].stop, "signup_not_ready ends the conversation")
	lu.assertEquals(#calls, 0, "startSpaceQuestChain calls")
	lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "grantStarterShip calls")
	lu.assertEquals(T.state(player, M1), "none", M1)
end

-- AC-7; space-convo-client-strings-dinge AC-3
function TestDingeSignup:test_yes_ship_shows_s_5ed33504_with_s_36a4e374_and_s_68660d24()
	local transcript = T.converse(tr, newcomer(true), { "s_d70dba34", "s_5c522568" })

	lu.assertEquals(transcript[3].id, "yes_ship", "third screen")
	lu.assertEquals(transcript[3].text, P .. "s_5ed33504", "yes_ship: NPC line")
	lu.assertEquals(texts(transcript[3].options), sids({ "s_36a4e374", "s_68660d24" }), "yes_ship: options")
	lu.assertEquals({ transcript[3].options[1].link, transcript[3].options[2].link }, { "signup_offer", "signup_not_ready" }, "yes_ship: links")
end

-- AC-7
function TestDingeSignup:test_an_enlisted_pilot_without_a_ship_and_no_mission_running_sees_no_ship_and_gets_the_starter_ship_once()
	local player = noShip(T.player(tr, 1, {}))
	local transcript = T.converse(tr, player)

	lu.assertEquals(ids(transcript), { "no_ship" }, "screens")
	lu.assertTrue(transcript[1].stop, "no_ship ends the conversation")
	lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 1, "grantStarterShip calls")
end

---------------------------------------------------------------------------------------------
-- AC-8: duty menu
---------------------------------------------------------------------------------------------

TestDingeDutyMenu = {}

function TestDingeDutyMenu:setUp() H.reset() end
function TestDingeDutyMenu:tearDown() restore() end

local function dutyPilot() return T.player(tr, 4, { win = { 1, 2, 3, 4 }, skills = { SKILLS_01[1] } }) end
local DUTY_OPTIONS = { "s_6106187c", "s_e814cf37", "s_db74ddc6", "s_2883b989" }

-- AC-8
function TestDingeDutyMenu:test_duty_missions_shows_the_four_swg_options_in_order()
	local transcript = T.converse(tr, dutyPilot())

	lu.assertEquals(transcript[1].id, "duty_missions", "first screen")
	lu.assertEquals(texts(transcript[1].options), sids(DUTY_OPTIONS), "options of duty_missions")
	lu.assertEquals({ transcript[1].options[1].link, transcript[1].options[2].link, transcript[1].options[3].link, transcript[1].options[4].link },
		{ "what_is_duty", "duty_options", "duty_no_training", "not_ready" }, "duty_missions: links")
end

-- AC-8
for i, target in ipairs({ "what_is_duty", "duty_no_training" }) do
	local pick = ({ 0, 2 })[i]

	TestDingeDutyMenu["test_option_" .. (pick + 1) .. "_of_the_duty_menu_leads_to_" .. target .. "_which_shows_the_same_four_options"] = function()
		local rec = T.spyAllQuests()
		local transcript = T.converse(tr, dutyPilot(), { pick, 0 })

		lu.assertEquals(transcript[2].id, target, "second screen")
		lu.assertEquals(texts(transcript[2].options), sids(DUTY_OPTIONS), target .. ": options")
		lu.assertFalse(transcript[2].stop, target .. " does not end the conversation")
		lu.assertEquals(rec.starts, {}, "startQuest calls")
	end
end

-- AC-8; space-convo-client-strings-dinge AC-6 / D-10: the decline rejoins not_ready, "OK, OK. Come back when you're ready."
function TestDingeDutyMenu:test_s_2883b989_ends_on_not_ready_and_starts_nothing()
	local rec = T.spyAllQuests()
	local transcript = T.converse(tr, dutyPilot(), { "s_2883b989" })

	lu.assertEquals(ids(transcript), { "duty_missions", "not_ready" }, "screens")
	lu.assertEquals(transcript[2].text, P .. "s_792ad840", "not_ready: NPC line")
	lu.assertTrue(transcript[2].stop, "not_ready ends the conversation")
	lu.assertEquals(transcript[2].options, {}, "not_ready: options")
	lu.assertEquals(rec.starts, {}, "startQuest calls")
end

-- AC-8
function TestDingeDutyMenu:test_duty_options_shows_the_three_swg_options()
	local transcript = T.converse(tr, dutyPilot(), { "s_e814cf37" })

	lu.assertEquals(ids(transcript), { "duty_missions", "duty_options" }, "screens")
	lu.assertEquals(texts(transcript[2].options), sids({ "s_40759c25", "s_629c7d23", "s_3d36a0e4" }), "options of duty_options")
	lu.assertFalse(transcript[2].stop, "duty_options does not end the conversation")
end

-- AC-8
function TestDingeDutyMenu:test_s_40759c25_starts_destroy_duty_6_exactly_as_before()
	local rec = T.spyAllQuests()
	local transcript = T.converse(tr, dutyPilot(), { "s_e814cf37", "s_40759c25" })

	lu.assertEquals(ids(transcript), { "duty_missions", "duty_options", "destroy_duty" }, "screens")
	lu.assertTrue(transcript[3].stop, "destroy_duty ends the conversation")
	lu.assertEquals(rec.starts, { DUTY6 }, "startQuest calls")
end

-- AC-8
function TestDingeDutyMenu:test_s_629c7d23_starts_escort_duty_7_exactly_as_before()
	local rec = T.spyAllQuests()
	local transcript = T.converse(tr, dutyPilot(), { "s_e814cf37", "s_629c7d23" })

	lu.assertEquals(ids(transcript), { "duty_missions", "duty_options", "escort_duty" }, "screens")
	lu.assertTrue(transcript[3].stop, "escort_duty ends the conversation")
	lu.assertEquals(rec.starts, { DUTY7 }, "startQuest calls")
end

-- AC-8
function TestDingeDutyMenu:test_s_3d36a0e4_ends_on_not_ready_and_starts_nothing()
	local rec = T.spyAllQuests()
	local transcript = T.converse(tr, dutyPilot(), { "s_e814cf37", "s_3d36a0e4" })

	lu.assertEquals(ids(transcript), { "duty_missions", "duty_options", "not_ready" }, "screens")
	lu.assertTrue(transcript[3].stop, "not_ready ends the conversation")
	lu.assertEquals(rec.starts, {}, "startQuest calls")
end

-- AC-8, D-8
function TestDingeDutyMenu:test_no_player_animation_is_recorded_when_duty_missions_is_the_first_screen()
	local player = dutyPilot()

	T.converse(tr, player)
	lu.assertEquals(player.animations or {}, {}, "player animations after duty_missions")
end

-- AC-8: the duty menu is reachable again after a duty ends (no duty running, tier skill held)
function TestDingeDutyMenu:test_a_pilot_with_a_finished_duty_and_a_tier_1_skill_sees_the_duty_menu_again()
	local player = T.player(tr, 4, { win = { 1, 2, 3, 4 }, skills = { SKILLS_01[1] }, complete = { DUTY6 } })

	lu.assertEquals(T.converse(tr, player)[1].id, "duty_missions", "first screen")
end

---------------------------------------------------------------------------------------------
-- AC-9: tier done
---------------------------------------------------------------------------------------------

TestDingeTierDoneAndTraining = {}

function TestDingeTierDoneAndTraining:setUp() H.reset() end
function TestDingeTierDoneAndTraining:tearDown() restore() end

-- AC-9
function TestDingeTierDoneAndTraining:test_completed_tier1_has_one_option_s_b3a9fd05_to_go_to_tier2()
	local transcript = T.converse(tr, T.player(tr, 1, { skills = SKILLS_01 }))

	lu.assertEquals(transcript[1].id, "completed_tier1", "first screen")
	lu.assertEquals(texts(transcript[1].options), { P .. "s_b3a9fd05" }, "options of completed_tier1")
	lu.assertEquals(transcript[1].options[1].link, "go_to_tier2", "completed_tier1: link")
end

-- AC-9
function TestDingeTierDoneAndTraining:test_go_to_tier2_raises_the_pilot_tier_from_1_to_2_and_ends()
	local player = T.player(tr, 1, { skills = SKILLS_01 })
	local transcript = T.converse(tr, player, { 0 })

	lu.assertEquals(ids(transcript), { "completed_tier1", "go_to_tier2" }, "screens")
	lu.assertTrue(transcript[2].stop, "go_to_tier2 ends the conversation")
	lu.assertEquals(player.ghost:getPilotTier(), 2, "pilot tier")
end

-- AC-9
function TestDingeTierDoneAndTraining:test_go_to_tier2_does_not_raise_a_pilot_who_is_already_past_tier_1()
	local player = T.player(tr, 1, { skills = SKILLS_01 })

	player.ghost.pilotTier = 2
	T.converse(tr, player, { 0 })
	lu.assertEquals(player.ghost:getPilotTier(), 2, "pilot tier")
end

-- (retired by rsf-tier1-dinge-training: the four old more_training / train_player_ / missions_complete tests are replaced by
-- test_rsf_tier1_dinge_training_purchase.lua)

---------------------------------------------------------------------------------------------
-- AC-10: the handler and the template agree (dynamic part, I-4, I-5)
---------------------------------------------------------------------------------------------

TestDingeHandlerSweep = {}

function TestDingeHandlerSweep:setUp() H.reset() end
function TestDingeHandlerSweep:tearDown() restore() end

-- AC-10, I-4, I-5: entering any one screen pays / starts exactly what the spec's start and pay tables list
function TestDingeHandlerSweep:test_entering_each_template_screen_pays_and_starts_only_what_the_spec_lists()
	local rec = T.spyAllQuests()
	local chainSnaps = H.spyOn(SpaceHelpers, "startSpaceQuestChain", function(self, pPlayer, pNpc, head)
		local n = 0

		for k, h in ipairs(D.HEADS) do
			if h == head then n = k end
		end

		return { head = head, attempted = n > 0 and H.getQuestStatus(pPlayer, D.KEYS[n] .. ":attempted") or nil }
	end)
	local entered = 0

	for _, screen in ipairs(H.conversationTemplateTable(tr.template).screens) do
		local id = screen.id
		local player = T.player(tr, 1, { attempted = false })
		local startsBefore, rewardsBefore, chainsBefore = #rec.starts, #rec.rewards, #chainSnaps
		local status = {}

		for n = 1, 4 do
			status[n] = { attempted(player, n), rewarded(player, n) }
		end

		enterScreen(player, id)
		entered = entered + 1

		local newRewards, newStarts, newChains = {}, {}, {}

		for k = rewardsBefore + 1, #rec.rewards do newRewards[#newRewards + 1] = rec.rewards[k] end
		for k = startsBefore + 1, #rec.starts do newStarts[#newStarts + 1] = rec.starts[k] end
		for k = chainsBefore + 1, #chainSnaps do newChains[#newChains + 1] = chainSnaps[k] end

		local wantReward = D.PAYS[id] and { D.HEADS[D.PAYS[id]] } or {}
		local wantStart = id == "destroy_duty" and { DUTY6 } or id == "escort_duty" and { DUTY7 } or {}

		lu.assertEquals(newRewards, wantReward, "screen '" .. id .. "': rewardPlayer calls")
		lu.assertEquals(newStarts, wantStart, "screen '" .. id .. "': startQuest calls")
		lu.assertEquals(#newChains, D.STARTS[id] and 1 or 0, "screen '" .. id .. "': startSpaceQuestChain calls")

		if D.STARTS[id] then
			lu.assertEquals(newChains[1].snapshot.head, D.HEADS[D.STARTS[id]], "screen '" .. id .. "': head started")
			lu.assertEquals(newChains[1].snapshot.attempted, "1", "screen '" .. id .. "': " .. D.KEYS[D.STARTS[id]] .. ":attempted when the chain starts (set first)")
		end

		for n = 1, 4 do
			lu.assertEquals(attempted(player, n), (D.STARTS[id] == n) and "1" or status[n][1], "screen '" .. id .. "': " .. D.KEYS[n] .. ":attempted afterwards")
			lu.assertEquals(rewarded(player, n), (D.PAYS[id] == n) and "1" or status[n][2], "screen '" .. id .. "': " .. D.KEYS[n] .. ":reward afterwards")
		end
	end

	lu.assertEquals(entered, D.SCREEN_COUNT_F2, "template screens entered (space-convo-client-strings-dinge: 64)")
end

-- AC-10, I-5: the start tables of the data file and of the generic suite agree
function TestDingeHandlerSweep:test_the_generic_trainer_data_lists_the_same_start_screens_as_the_spec()
	for n = 1, 4 do
		local want = {}

		for id, m in pairs(D.STARTS) do
			if m == n then want[#want + 1] = id end
		end

		table.sort(want)

		local got = T.startScreens(tr, n)

		table.sort(got)
		lu.assertEquals(got, want, "trainer_fixes_data: Dinge mission " .. n .. " start screens")
	end

	lu.assertTrue(tr.usesAttempted, "trainer_fixes_data: Dinge usesAttempted")
end

-- AC-10, I-4: a mission's pay screen entered twice in one conversation pays twice only if the engine shows it twice; the engine shows
-- it once, and the routing never returns to it after the key is set
function TestDingeHandlerSweep:test_no_first_screen_in_any_state_pays_a_mission_that_is_already_paid()
	for n = 1, 4 do
		local player = T.player(tr, n, { complete = tr.chains[n] })

		H.setQuestStatus(player, D.KEYS[n] .. ":reward", 1)

		local rec = T.spyRewards()

		lu.assertNotEquals(T.converse(tr, player)[1].id, "mission" .. n .. "_reward", "mission " .. n .. ": first screen of a paid pilot")
		lu.assertEquals(rec.rewards, {}, "mission " .. n .. ": rewardPlayer calls")
	end
end
