-- Shamdon Kree: the four briefings and retries start their mission once and mark it attempted; the duty screens start their duty.
-- Spec: .claude/work/smuggler-tier2-shamdon/01-spec.md (AC-6 S7-S10, AC-8; Conversation flow 3 (table H); Content contract 3 (START_SCREENS, DUTY_SCREENS); D-4).
--
-- Quest starts are observed with spies on every quest table's startQuest (the original is not called); the real start is covered by
-- test_smuggler_tier2_runtime.lua (TestSmugglerT2Chain).

local lu = require("luaunit")
local H = require("harness")
local M = require("smuggler_tier2_data")
local CS = require("harness.client_strings")

M.load()

local spies

local function setUp()
	H.reset()
	M.requireConversation(lu)
	spies = {}

	for _, g in ipairs(M.questTables()) do
		spies[g] = H.spyOn(rawget(_G, g), "startQuest")
	end
end

-- the globals whose startQuest was called, sorted
local function started()
	local out = {}

	for g, calls in pairs(spies) do
		for _ = 1, #calls do
			out[#out + 1] = g
		end
	end

	table.sort(out)
	return out
end

TestSmugglerT2Missions = {}

TestSmugglerT2Missions.setUp = setUp

for n = 1, 4 do
	local head = M.HEADS[n]
	local key = M.STATUS_NAMES[n] .. ":attempted"

	-- AC-8: the briefing sets the key and starts the mission once
	TestSmugglerT2Missions["test_m" .. n .. "_brief_marks_mission_" .. n .. "_attempted_and_starts_it_once"] = function()
		local player = M.pilot({ skills2 = { M.trainFor(n).x } })
		local t = M.drive(player, "m" .. n .. "_brief")

		lu.assertEquals(M.ids(t), { "m" .. n .. "_brief" }, "screen shown")
		lu.assertTrue(t[1].stop, "m" .. n .. "_brief ends the conversation")
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
		lu.assertEquals(started(), { head }, "quests started")
		lu.assertEquals(spies[head][1].args[1], player, head .. ":startQuest gets the pilot")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-6 S7-S10: the retry restarts the failed mission once and keeps the key
	TestSmugglerT2Missions["test_m" .. n .. "_retry_restarts_mission_" .. n .. "_once"] = function()
		local player = M.pilot({ tier2 = 4, missions = { [n] = "attempted" } })
		local t = M.talk(player)

		lu.assertEquals(M.ids(t), { "m" .. n .. "_retry" }, "first screen")
		lu.assertTrue(t[1].stop, "m" .. n .. "_retry ends the conversation")
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
		lu.assertEquals(started(), { head }, "quests started")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-8: the other missions' keys stay unset
	TestSmugglerT2Missions["test_m" .. n .. "_brief_sets_only_its_own_key"] = function()
		local player = M.pilot({ skills2 = { M.trainFor(n).x } })

		M.drive(player, "m" .. n .. "_brief")

		for k = 1, 4 do
			if k ~= n then
				lu.assertNil(H.getQuestStatus(player, M.STATUS_NAMES[k] .. ":attempted"), "mission " .. k .. " :attempted")
			end
		end

		lu.assertNil(H.getQuestStatus(player, M.STATUS_NAMES[n] .. ":reward"), "mission " .. n .. " :reward")
	end
end

-- AC-8, D-4: the briefing a skill leads to is the skill's mission, never the next number (SHJ's NGE mapping)
function TestSmugglerT2Missions:test_the_skill_to_mission_mapping_is_starships_1_droid_2_weapons_3_procedures_4()
	lu.assertEquals(M.trainFor(1).skill, "pilot_neutral_starships_02", "mission 1")
	lu.assertEquals(M.trainFor(2).skill, "pilot_neutral_droid_02", "mission 2")
	lu.assertEquals(M.trainFor(3).skill, "pilot_neutral_weapons_02", "mission 3")
	lu.assertEquals(M.trainFor(4).skill, "pilot_neutral_procedures_02", "mission 4")
end

-- AC-6: the retry of a mission is not offered while another trainer's quest holds the pilot (busy first)
function TestSmugglerT2Missions:test_a_retry_screen_is_not_reached_while_busy()
	local player = M.pilot({ tier2 = 1, missions = { [1] = "attempted" }, datapad = "story" })

	lu.assertEquals(M.ids(M.talk(player)), { "busy" }, "first screen")
	lu.assertEquals(started(), {}, "quests started")
end

-- AC-6: the duty screens start exactly their duty, shown by themselves
function TestSmugglerT2Missions:test_each_duty_screen_starts_only_its_duty()
	local cases = { { "duty_escort", M.DUTY_ESCORT }, { "duty_recovery", M.DUTY_RECOVERY }, { "duty_destroy", M.DUTY_DESTROY } }

	for _, c in ipairs(cases) do
		H.reset()
		setUp()

		local t = M.drive(M.pilot({}), c[1])

		lu.assertTrue(t[1].stop, c[1] .. " ends the conversation")
		lu.assertEquals(started(), { c[2] }, c[1] .. ": quests started")
	end
end

-- AC-6: the duty offer on the default screen lists the three duties in the SWG menu order
function TestSmugglerT2Missions:test_the_duty_offer_lists_escort_recovery_and_destroy_in_that_order()
	local t = M.talk(M.pilot({}), { "s_f4b9423e" })

	lu.assertEquals(M.ids(t), { "work", "duty_offer" }, "walk")
	lu.assertEquals(M.optionSids(t[2]), { "s_c631f8da", "s_6ff30da7", "s_93ba78e7" }, "duty_offer replies")
	lu.assertEquals(M.linksOf(t[2]), { "duty_escort", "duty_recovery", "duty_destroy" }, "duty_offer links")
end

-- AC-6: the other screens start nothing and pay nothing
function TestSmugglerT2Missions:test_the_non_mission_screens_start_and_set_nothing()
	local none = { "not_pilot", "off_track", "off_track_refused", "stranger", "never_mind", "talon_only", "talon_who_male", "talon_what", "busy", "come_back", "come_back_soon", "duty_menu",
		"not_yet", "work", "work_no", "duty_offer", "off_track_duties", "ready_mission" }

	for _, id in ipairs(none) do
		H.reset()
		setUp()

		local player = M.pilot({ skills2 = { "starships" } })
		local before = M.snapshot(player)

		M.drive(player, id)
		lu.assertEquals(started(), {}, id .. ": quests started")
		lu.assertEquals(M.snapshot(player), before, id .. ": player state")
	end
end
