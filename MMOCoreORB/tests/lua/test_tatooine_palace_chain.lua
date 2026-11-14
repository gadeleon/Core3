-- Tatooine station palace access: the quest chain (rescue -> delivery -> battle -> assassinate) and quest 4's auto reward.
-- Spec: .claude/work/tatooine-station-palace-access/01-spec.md (AC-2, AC-3; Data mapping quests 1-4; D-9, D-13; R-7).
--
-- The split timing is the shared quest types' own (alert at sideQuestDelay s, child start 50 ms per second later), so the tests advance 6 s, like the spec
-- says "5 s later". Downstream startQuest calls are spied (H.spyOn) so a test stops at "started"; one test per link also lets the child run for real.

local lu = require("luaunit")
local H = require("harness")
local P = require("tatooine_palace_data")

P.load()

local G = P.GLOBALS
local ALERT = "@space/quest:quest_alert_s"

local function isolate()
	local spies = {}

	for _, global in ipairs(G) do
		spies[global] = H.spyOn(P.quest(global), "startQuest")
	end

	return spies
end

local function started(spies)
	local out = {}

	for _, global in ipairs(G) do
		if #spies[global] > 0 then
			out[#out + 1] = global .. " x" .. #spies[global]
		end
	end

	return out
end

local function alerts(player)
	local out = {}

	for _, m in ipairs(H.messageLog(player)) do
		if m.id == ALERT then
			out[#out + 1] = m.TO
		end
	end

	return out
end

local function alertOf(global) return "@spacequest/" .. P.IDENTITY[global].type .. "/" .. P.IDENTITY[global].name .. ":split_quest_alert" end

local function pilot() return P.pilot({ name = "Han" }) end

---------------------------------------------------------------------------------------------
-- AC-2: the chain
---------------------------------------------------------------------------------------------

TestPalaceSplits = {}

function TestPalaceSplits:setUp() H.reset() end

-- AC-2
function TestPalaceSplits:test_completing_quest_1_starts_quest_2_five_seconds_later_and_sends_its_alert()
	local player = pilot()
	local spies = isolate()

	P.setState(player, G[1], "active")
	P.quest(G[1]):completeQuest(player, "true")
	lu.assertEquals(P.state(player, G[1]), "complete", "quest 1 is complete")

	H.advance(4900)
	lu.assertEquals(started(spies), {}, "nothing started before the 5 s are up")
	lu.assertEquals(alerts(player), {}, "no alert before the 5 s are up")

	H.advance(1100)
	lu.assertEquals(started(spies), { G[2] .. " x1" }, "quest 2 started once, nothing else")
	lu.assertEquals(spies[G[2]][1].args[1], player, "quest 2 started for the pilot")
	lu.assertEquals(alerts(player), { alertOf(G[1]) }, "quest 1's split_quest_alert, once")
end

-- AC-2
function TestPalaceSplits:test_completing_quest_2_starts_quest_3_five_seconds_later_and_sends_its_alert()
	local player = pilot()
	local spies = isolate()

	P.setState(player, G[2], "active")
	P.quest(G[2]):completeQuest(player, "true")
	H.advance(4900)
	lu.assertEquals(started(spies), {}, "nothing started before the 5 s are up")
	H.advance(1100)
	lu.assertEquals(started(spies), { G[3] .. " x1" }, "quest 3 started once, nothing else")
	lu.assertEquals(alerts(player), { alertOf(G[2]) }, "quest 2's split_quest_alert, once")
end

-- AC-2: the win branch of the battle
function TestPalaceSplits:test_completing_quest_3_starts_quest_4_once()
	local player = pilot()
	local spies = isolate()

	P.setState(player, G[3], "active")
	P.quest(G[3]):completeQuest(player, "true")
	H.advance(6000)
	lu.assertEquals(started(spies), { G[4] .. " x1" }, "quest 4 started once, nothing else")
	lu.assertEquals(alerts(player), { alertOf(G[3]) }, "quest 3's split_quest_alert, once")
end

-- AC-2: the lose branch of the battle (BIDIRECTIONAL)
function TestPalaceSplits:test_failing_quest_3_also_starts_quest_4_once()
	local player = pilot()
	local spies = isolate()

	P.setState(player, G[3], "active")
	P.quest(G[3]):failQuest(player, "true")
	lu.assertEquals(P.state(player, G[3]), "none", "quest 3 is no longer active")
	H.advance(6000)
	lu.assertEquals(started(spies), { G[4] .. " x1" }, "quest 4 started once, nothing else")
	lu.assertEquals(alerts(player), { alertOf(G[3]) }, "quest 3's split_quest_alert, once")
end

-- AC-2: quests 1 and 2 split on success only
function TestPalaceSplits:test_failing_quest_1_or_2_starts_nothing()
	for _, i in ipairs({ 1, 2 }) do
		H.reset()

		local player = pilot()
		local spies = isolate()

		P.setState(player, G[i], "active")
		P.quest(G[i]):failQuest(player, "true")
		H.advance(10000)
		lu.assertEquals(started(spies), {}, "failing quest " .. i .. " starts nothing")
		lu.assertEquals(alerts(player), {}, "failing quest " .. i .. " sends no split alert")
	end
end

-- AC-2, I-4: the end of the chain
function TestPalaceSplits:test_completing_or_failing_quest_4_starts_nothing()
	for _, outcome in ipairs({ "completeQuest", "failQuest" }) do
		H.reset()

		local player = pilot()
		local spies = isolate()

		P.setState(player, G[4], "active")
		P.quest(G[4])[outcome](P.quest(G[4]), player, "true")
		H.advance(10000)
		lu.assertEquals(started(spies), {}, "quest 4 " .. outcome .. " starts nothing")
		lu.assertEquals(alerts(player), {}, "quest 4 " .. outcome .. " sends no split alert")
	end
end

-- AC-2: the whole chain runs on the event clock, each link starting its successor for real
function TestPalaceSplits:test_the_children_really_become_active_when_they_are_allowed_to_start()
	local player = P.pilot({ name = "Han", zone = "space_yavin4" })

	P.setState(player, G[1], "active")
	P.quest(G[1]):completeQuest(player, "true")
	H.advance(6000)
	lu.assertEquals(P.state(player, G[2]), "active", "quest 2 is active 6 s after quest 1 completed")
	lu.assertEquals(P.state(player, G[1]), "complete", "quest 1 stays complete")

	P.quest(G[2]):completeQuest(player, "true")
	H.advance(6000)
	lu.assertEquals(P.state(player, G[3]), "active", "quest 3 is active 6 s after quest 2 completed")
end

---------------------------------------------------------------------------------------------
-- AC-3: the auto reward of quest 4
---------------------------------------------------------------------------------------------

TestPalaceAutoReward = {}

function TestPalaceAutoReward:setUp() H.reset() end

local FROM = "@spacequest/assassinate/tatooine_station_hutt_palace_access_quest_4:autorewardfrom"
local SUBJECT = "@spacequest/assassinate/tatooine_station_hutt_palace_access_quest_4:autorewardsubject"
local BODY = "@spacequest/assassinate/tatooine_station_hutt_palace_access_quest_4:autorewardbody"

local function rewardMessages(player)
	local out = {}

	for _, m in ipairs(H.messageLog(player)) do
		if m.id == "@space/quest:quest_reward" then
			out[#out + 1] = m
		end
	end

	return out
end

local function assertNothingPaid(player, label)
	lu.assertEquals(#player.bankCreditLog, 0, label .. ": addBankCredits calls")
	lu.assertEquals(player.bankCredits, 0, label .. ": bank credits")
	lu.assertEquals(#rewardMessages(player), 0, label .. ": @space/quest:quest_reward messages")
	lu.assertEquals(#H.Engine.callsTo("sendMail"), 0, label .. ": sendMail calls")
end

-- AC-3
function TestPalaceAutoReward:test_completing_quest_4_pays_10000_to_the_bank_once_with_the_reward_message()
	local player = pilot()

	P.setState(player, G[4], "active")
	P.quest(G[4]):completeQuest(player, "true")

	lu.assertEquals(P.state(player, G[4]), "complete", "quest 4 is complete")
	lu.assertEquals(player.bankCredits, 10000, "the bank grew by exactly 10000")
	lu.assertEquals(#player.bankCreditLog, 1, "one addBankCredits call")

	local msgs = rewardMessages(player)

	lu.assertEquals(#msgs, 1, "one @space/quest:quest_reward message")
	lu.assertEquals(msgs[1] and msgs[1].DI, 10000, "quest_reward DI")
	lu.assertFalse(msgs[1] ~= nil and msgs[1].plain, "quest_reward is a string-id message with a DI parameter")
end

-- AC-3: one mail with the three autoreward ids, addressed to the pilot's first name
function TestPalaceAutoReward:test_completing_quest_4_sends_one_bank_statement_mail()
	local player = pilot()

	P.setState(player, G[4], "active")
	P.quest(G[4]):completeQuest(player, "true")

	local mails = H.Engine.callsTo("sendMail")

	lu.assertEquals(#mails, 1, "one sendMail call")
	lu.assertEquals({ mails[1][1], mails[1][2], mails[1][3], mails[1][4] }, { FROM, SUBJECT, BODY, "Han" }, "sendMail(sender, subject, body, recipient)")
end

-- AC-3: later events do not pay again
function TestPalaceAutoReward:test_the_reward_is_paid_once_even_after_the_event_clock_runs()
	local player = pilot()

	P.setState(player, G[4], "active")
	P.quest(G[4]):completeQuest(player, "true")
	H.advance(60000)
	lu.assertEquals(player.bankCredits, 10000, "bank after a minute")
	lu.assertEquals(#H.Engine.callsTo("sendMail"), 1, "mails after a minute")
end

-- AC-3: fail, reset and abort pay nothing
function TestPalaceAutoReward:test_failing_quest_4_pays_nothing()
	local player = pilot()

	P.setState(player, G[4], "active")
	P.quest(G[4]):failQuest(player, "true")
	H.advance(10000)
	assertNothingPaid(player, "fail")
end

function TestPalaceAutoReward:test_resetting_quest_4_pays_nothing()
	local player = pilot()

	P.setState(player, G[4], "active")
	P.quest(G[4]):resetQuest(player)
	H.advance(10000)
	assertNothingPaid(player, "reset")
end

function TestPalaceAutoReward:test_aborting_quest_4_pays_nothing()
	local player = pilot()

	P.setState(player, G[4], "active")
	P.quest(G[4]):abortQuest(player)
	H.advance(10000)
	assertNothingPaid(player, "abort")
end

-- AC-3: a completion that arrives after the quest ended (fail timer fired first) pays nothing
function TestPalaceAutoReward:test_completing_quest_4_after_it_failed_pays_nothing()
	local player = pilot()

	P.setState(player, G[4], "active")
	P.quest(G[4]):failQuest(player, "true")
	P.quest(G[4]):completeQuest(player, "true")
	H.advance(10000)
	assertNothingPaid(player, "completion after fail")
	lu.assertEquals(P.state(player, G[4]), "none", "quest 4 stays failed, not complete")
end

-- AC-3: a completion that arrives after a datapad abort pays nothing
function TestPalaceAutoReward:test_completing_quest_4_after_an_abort_pays_nothing()
	local player = pilot()

	P.setState(player, G[4], "active")
	P.quest(G[4]):abortQuest(player)
	P.quest(G[4]):completeQuest(player, "true")
	H.advance(10000)
	assertNothingPaid(player, "completion after abort")
end

-- AC-3: a completion for a quest that was never started pays nothing
function TestPalaceAutoReward:test_completing_quest_4_when_it_was_never_active_pays_nothing()
	local player = pilot()

	P.quest(G[4]):completeQuest(player, "true")
	assertNothingPaid(player, "completion without an active quest")
end

-- AC-3: a second completion of the same run pays nothing more
function TestPalaceAutoReward:test_completing_quest_4_twice_pays_once()
	local player = pilot()

	P.setState(player, G[4], "active")
	P.quest(G[4]):completeQuest(player, "true")
	P.quest(G[4]):completeQuest(player, "true")
	lu.assertEquals(player.bankCredits, 10000, "bank after two completions")
	lu.assertEquals(#H.Engine.callsTo("sendMail"), 1, "mails after two completions")
	lu.assertEquals(#rewardMessages(player), 1, "reward messages after two completions")
end

-- AC-3: quests 1-3 completing pay nothing
function TestPalaceAutoReward:test_completing_quests_1_to_3_pays_nothing()
	for i = 1, 3 do
		H.reset()

		local player = pilot()
		local spies = isolate()

		P.setState(player, G[i], "active")
		P.quest(G[i]):completeQuest(player, "true")
		H.advance(10000)
		assertNothingPaid(player, "quest " .. i .. " completion")
		lu.assertEquals(#spies[G[i]], 0, "quest " .. i .. " does not restart itself")
	end
end
