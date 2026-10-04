-- Space recovery and recovery-duty fixes, run-time behavior: the captured ship is re-added as a mission object, the six recovery duties pay,
-- the attack-ship list survives a second wave, every recovery quest spawns its target, and the capture taunts use keys the client has.
-- Spec: .claude/work/space-recovery-duty-fixes/01-spec.md (AC-1 .. AC-4, AC-7, AC-8, C-1, C-2, invariants I-1, I-3, I-4, I-6).
--
-- The set of quests is discovered at run time (every global whose class chain reaches SpaceRecoveryScreenplay) and compared with the 12 of the spec,
-- so a quest that silently drops out of the loop fails the set test instead of shrinking the coverage.
-- Strict ship names: RF.start switches on H.Engine.config.rejectEmptyShipName, so a quest table that spawns a ship with the template name ""
-- gets nil from spawnShipAgent like the server does (before this feature the fake accepted "" and hid the Havoc bug).

local lu = require("luaunit")
local H = require("harness")
local DR = require("duty_rules_scenario")
local RF = require("recovery_fixes_scenario")
local CS = require("harness.client_strings")

RF.load()

local RECOVERY = RF.recoveryGlobals()
local DUTIES = RF.dutyGlobals()
local STORIES = RF.storyGlobals()

local function sortedKeys(t)
	local out = {}

	for k in pairs(t) do
		out[#out + 1] = k
	end

	table.sort(out)
	return out
end

local function fileExists(path)
	local f = io.open(path, "r")

	if f == nil then
		return false
	end

	f:close()
	return true
end

local function setOf(list)
	local out = {}

	for _, v in ipairs(list) do
		out[v] = true
	end

	return out
end

local function pendingMethods()
	local out = {}

	for _, e in ipairs(H.pendingEvents()) do
		out[#out + 1] = e.method
	end

	table.sort(out)
	return out
end

local function messageIds(player)
	local out = {}

	for _, m in ipairs(H.messageLog(player)) do
		out[#out + 1] = m
	end

	return out
end

local function dutyEntryCleared(run)
	return not DR.active(run.player, run.quest) and not DR.complete(run.player, run.quest)
end

local function readKey(run, suffix) return readData(RF.key(run, suffix)) end

---------------------------------------------------------------------------------------------
-- The set (I-1)
---------------------------------------------------------------------------------------------

TestRecoveryFixesSet = {}

function TestRecoveryFixesSet:setUp() H.reset() end

-- AC-1 (I-1): the 12 recovery quests of the three squadrons; CorSec duty 12 is one of them once it is rebuilt
function TestRecoveryFixesSet:test_the_twelve_recovery_quests_are_loaded()
	lu.assertEquals(RECOVERY, sortedKeys(RF.EXPECTED), "globals whose class chain reaches SpaceRecoveryScreenplay")
end

-- AC-3 (I-2): the six recovery duties
function TestRecoveryFixesSet:test_six_of_them_are_recovery_duties_on_the_duty_base()
	local want = {}

	for global, kind in pairs(RF.EXPECTED) do
		if kind == "duty" then
			want[#want + 1] = global
		end
	end

	table.sort(want)
	lu.assertEquals(DUTIES, want, "globals whose class chain reaches SpaceDutyRecoveryScreenplay")
end

---------------------------------------------------------------------------------------------
-- AC-1, AC-2, AC-7, AC-8: every recovery quest
---------------------------------------------------------------------------------------------

TestRecoveryFixesEveryQuest = {}

function TestRecoveryFixesEveryQuest:setUp() H.reset() end

function TestRecoveryFixesEveryQuest:tearDown()
	DR.restoreRecoveryTables()
	H.Engine.config.rejectEmptyShipName = nil
end

for _, global in ipairs(sortedKeys(RF.EXPECTED)) do
	-- AC-1: the captured ship is removed as a mission object and added back, with its own id and last = true
	TestRecoveryFixesEveryQuest["test_" .. global .. "_re_adds_the_captured_ship_as_a_mission_object"] = function()
		local run = RF.start(global)
		local p, ship = run.player, run.ship
		local addsBefore, removalsBefore = #p.missionObjectLog, #p.removedMissionObjectLog

		RF.capture(run)

		local adds, removals = {}, {}

		for i = addsBefore + 1, #p.missionObjectLog do
			adds[#adds + 1] = p.missionObjectLog[i]
		end

		for i = removalsBefore + 1, #p.removedMissionObjectLog do
			removals[#removals + 1] = p.removedMissionObjectLog[i].id
		end

		for i, e in ipairs(adds) do
			lu.assertNotNil(e.id, global .. ": addSpaceMissionObject call " .. i .. " after the capture started has an id (nil is the undefined recoveryAgentID)")
		end

		lu.assertEquals(RF.count(removals, ship.objectID), 1, global .. ": the captured ship " .. ship.objectID .. " is removed once as a mission object")

		local readded = 0

		for _, e in ipairs(adds) do
			if e.id == ship.objectID then
				readded = readded + 1
				lu.assertEquals(e.last, true, global .. ": the re-added ship is the last mission object")
			end
		end

		lu.assertEquals(readded, 1, global .. ": the captured ship " .. ship.objectID .. " is added back once")
		lu.assertEquals(RF.count(p.missionObjects, ship.objectID), 1, global .. ": the captured ship is a mission object at the end of the capture")
		lu.assertEquals(readData(ship.objectID .. ":" .. run.quest.className .. ":recoveryShipProgress:"), #run.quest.recoveryPoints, global .. ": recoveryShipProgress")
	end

	-- AC-2: the captured ship completes the quest once, after the last recovery area; an area entry before the capture does nothing
	TestRecoveryFixesEveryQuest["test_" .. global .. "_completes_once_after_the_last_recovery_area_of_a_real_capture"] = function()
		local run = RF.start(global)
		local q, n = run.quest, #run.quest.recoveryPoints

		lu.assertTrue(n >= 1, global .. ": at least one recovery point")

		H.enterArea(run.areas[n], run.ship)
		lu.assertEquals(RF.count(pendingMethods(), "completeQuest"), 0, global .. ": an area entry before the capture schedules no completeQuest")
		lu.assertTrue(DR.active(run.player, q), global .. ": still active after an area entry before the capture")

		RF.capture(run)

		for i = 1, n - 1 do
			H.enterArea(run.areas[i], run.ship)
			lu.assertEquals(RF.count(pendingMethods(), "completeQuest"), 0, global .. ": no completeQuest after recovery area " .. i .. " of " .. n)
			lu.assertTrue(DR.active(run.player, q), global .. ": still active after recovery area " .. i)
		end

		H.enterArea(run.areas[n], run.ship)
		lu.assertEquals(RF.count(pendingMethods(), "completeQuest"), 1, global .. ": exactly one completeQuest after the last recovery area")

		H.advance(1000)
		lu.assertFalse(DR.active(run.player, q), global .. ": the quest is over after the completeQuest event")
		lu.assertEquals(RF.count(pendingMethods(), "completeQuest"), 0, global .. ": the completeQuest event ran")

		if RF.EXPECTED[global] == "story" then
			lu.assertTrue(DR.complete(run.player, q), global .. ": a story recovery is complete")
			lu.assertEquals(#DR.messages(run.player, RF.MSG_REWARD), 0, global .. ": a story recovery sends no recovery_reward (the trainer pays it)")
		else
			lu.assertTrue(dutyEntryCleared(run), global .. ": a duty clears its journal entry")
		end
	end

	-- AC-7 (I-4): the target is a real template of the .tab targetShipTypes
	TestRecoveryFixesEveryQuest["test_" .. global .. "_spawns_a_target_from_its_tab_target_ship_types"] = function()
		local run = RF.start(global)
		local rec = RF.fixtureOf(run.quest)
		local allowed = setOf(RF.targetTypes(rec))
		local name = run.ship.shipName

		lu.assertTrue(#RF.targetTypes(rec) >= 1, global .. ": the fixture lists a target ship type")
		lu.assertNotEquals(name, "", global .. ": the recovery ship has a template name")
		lu.assertTrue(allowed[name] == true, global .. ": recovery ship '" .. tostring(name) .. "' is one of " .. table.concat(RF.targetTypes(rec), ", "))
		lu.assertTrue(fileExists(H.SCRIPTS .. "ship_mobile/ships/" .. name .. ".lua"), global .. ": ship_mobile/ships/" .. name .. ".lua exists")

		for i, call in ipairs(H.Engine.callsTo("spawnShipAgent")) do
			lu.assertNotEquals(call[1], "", global .. ": spawnShipAgent call " .. i .. " has a template name")
		end
	end

	-- AC-8 / I-5: every string the quest sends over a whole run resolves in the pre-NGE client
	TestRecoveryFixesEveryQuest["test_" .. global .. "_sends_only_strings_the_client_has_over_a_whole_run"] = function()
		local run = RF.start(global)

		RF.capture(run)

		local wave = RF.wave(run)

		RF.killAll(run, wave)
		RF.finish(run)

		local seen = {}

		for _, msg in ipairs(RF.taunts(run)) do
			seen[#seen + 1] = { "taunt", msg }
		end

		for _, m in ipairs(messageIds(run.player)) do
			seen[#seen + 1] = { m.plain and "plain message" or "message", m.id }
		end

		lu.assertTrue(#seen >= 5, global .. ": the run produced " .. #seen .. " strings")

		for _, s in ipairs(seen) do
			local file, id = s[2]:match("^@([^:]+):(.+)$")

			lu.assertNotNil(file, global .. ": " .. s[1] .. " '" .. s[2] .. "' is a string id, not hard-coded text")

			local ids, why = CS.sids(file)

			lu.assertNotNil(ids, global .. ": " .. s[1] .. " '" .. s[2] .. "': " .. tostring(why))
			lu.assertTrue(ids[id] == true, global .. ": " .. s[1] .. " '@" .. file .. ":" .. id .. "' is in the pre-NGE client")
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-7: the random pick of recoverShips (C-1d)
---------------------------------------------------------------------------------------------

TestRecoveryFixesTargetPick = {}

function TestRecoveryFixesTargetPick:setUp() H.reset() end

function TestRecoveryFixesTargetPick:tearDown()
	DR.restoreRecoveryTables()
	H.Engine.config.rejectEmptyShipName = nil

	if self.restore ~= nil then
		self.restore()
		self.restore = nil
	end
end

-- AC-7: both target types of the two duties that have two occur
for _, global in ipairs({ "recovery_duty_viopa_rebel_7", "recovery_duty_corellia_privateer_12" }) do
	for k = 1, 2 do
		TestRecoveryFixesTargetPick["test_" .. global .. "_spawns_target_type_" .. k .. "_when_the_pick_is_" .. k] = function()
			local q = H.expectGlobal(global, "recovery duty quest table")
			local want = RF.targetTypes(RF.fixtureOf(q))

			lu.assertEquals(#want, 2, global .. ": the fixture lists two target ship types")
			H.Engine.setRandom(1, #want, k)

			local run = RF.start(global)

			lu.assertEquals(run.ship.shipName, want[k], global .. ": the recovery ship when getRandomNumber(1, " .. #want .. ") returns " .. k)
		end
	end
end

-- AC-7 (C-1d): the default is no list; an empty list falls back to recoverShip
function TestRecoveryFixesTargetPick:test_the_base_has_no_recover_ships_list_by_default()
	lu.assertEquals(#(SpaceRecoveryScreenplay.recoverShips or {}), 0, "SpaceRecoveryScreenplay.recoverShips")
	lu.assertEquals(#(SpaceDutyRecoveryScreenplay.recoverShips or {}), 0, "SpaceDutyRecoveryScreenplay.recoverShips")
end

-- AC-7 (C-1d)
function TestRecoveryFixesTargetPick:test_an_empty_recover_ships_list_falls_back_to_recover_ship()
	local q = H.expectGlobal("recovery_duty_naboo_privateer_10", "recovery duty quest table")
	local want = q.recoverShip

	lu.assertEquals(want, "ndc_duty_transport_tier2", "setup: duty 10's single target")

	q.recoverShips = {}
	self.restore = function() q.recoverShips = nil end

	local run = RF.start("recovery_duty_naboo_privateer_10")

	lu.assertEquals(run.ship.shipName, want, "recovery ship with recoverShips = {}")
end

-- AC-7 (C-1d): a list wins over recoverShip
function TestRecoveryFixesTargetPick:test_a_recover_ships_list_wins_over_recover_ship()
	local q = H.expectGlobal("recovery_duty_naboo_privateer_10", "recovery duty quest table")

	q.recoverShips = { "nym_freightermedium_tier3", "nym_smuggler_freightermedium_tier4" }
	self.restore = function() q.recoverShips = nil end
	H.Engine.setRandom(1, 2, 2)

	local run = RF.start("recovery_duty_naboo_privateer_10")

	lu.assertEquals(run.ship.shipName, "nym_smuggler_freightermedium_tier4", "recovery ship with a two-entry list and a pick of 2")
end

---------------------------------------------------------------------------------------------
-- AC-8: the capture taunt keys (C-1e, C-2)
---------------------------------------------------------------------------------------------

TestRecoveryFixesCaptureKeys = {}

function TestRecoveryFixesCaptureKeys:setUp() H.reset() end

function TestRecoveryFixesCaptureKeys:tearDown()
	DR.restoreRecoveryTables()
	H.Engine.config.rejectEmptyShipName = nil
end

-- AC-8 (C-1e): the base keys
function TestRecoveryFixesCaptureKeys:test_the_base_capture_key_is_capture_phase_n()
	lu.assertEquals(type(SpaceRecoveryScreenplay.capturePhraseKey), "function", "SpaceRecoveryScreenplay.capturePhraseKey")
	lu.assertEquals(SpaceRecoveryScreenplay:capturePhraseKey(1), "capture_phase_1", "phase 1")
	lu.assertEquals(SpaceRecoveryScreenplay:capturePhraseKey(2), "capture_phase_2", "phase 2")
end

-- AC-8 (C-2): the duty base has numResponses = 0, so it keeps the base key; the pay defaults are 0
function TestRecoveryFixesCaptureKeys:test_the_duty_base_defaults_to_no_numbered_keys_and_no_kill_bonus()
	lu.assertEquals(SpaceDutyRecoveryScreenplay.numResponses, 0, "SpaceDutyRecoveryScreenplay.numResponses")
	lu.assertEquals(SpaceDutyRecoveryScreenplay.creditKillBonus, 0, "SpaceDutyRecoveryScreenplay.creditKillBonus")
	lu.assertEquals(SpaceDutyRecoveryScreenplay:capturePhraseKey(2), "capture_phase_2", "numResponses 0 keeps the base key")
end

-- AC-8 (C-2): numbered keys with k = getRandomNumber(1, numResponses)
function TestRecoveryFixesCaptureKeys:test_a_duty_with_responses_draws_k_from_one_to_num_responses()
	local q = H.expectGlobal("recovery_duty_naboo_privateer_10", "recovery duty quest table")

	lu.assertEquals(q.numResponses, 5, "setup: duty 10 numResponses")
	H.Engine.setRandom(1, 5, 4)
	lu.assertEquals(q:capturePhraseKey(1), "capture_phase_1_4", "phase 1 with a draw of 4")
	lu.assertEquals(q:capturePhraseKey(2), "capture_phase_2_4", "phase 2 with a draw of 4")
end

-- AC-8: each story recovery taunts exactly capture_phase_1 and capture_phase_2
for _, global in ipairs(STORIES) do
	TestRecoveryFixesCaptureKeys["test_" .. global .. "_taunts_capture_phase_1_and_capture_phase_2"] = function()
		local run = RF.start(global)

		RF.capture(run)
		lu.assertEquals(RF.keysOf(run, "capture_phase"), { "capture_phase_1", "capture_phase_2" }, global .. ": capture taunts")
	end
end

-- AC-8: each duty taunts capture_phase_1_k and capture_phase_2_k, 1 <= k <= numResponses, at both ends of the range
for _, global in ipairs(DUTIES) do
	for _, end_ in ipairs({ "first", "last" }) do
		TestRecoveryFixesCaptureKeys["test_" .. global .. "_taunts_numbered_capture_keys_within_num_responses_at_the_" .. end_ .. "_draw"] = function()
			local q = H.expectGlobal(global, "recovery duty quest table")
			local n = q.numResponses
			local k = end_ == "first" and 1 or n

			lu.assertTrue(n ~= nil and n >= 1, global .. ": numResponses " .. tostring(n))

			if RF.EXPECTED[global] == "duty" and q.recoverShips ~= nil and #q.recoverShips > 0 then
				H.Engine.setRandom(1, #q.recoverShips, 1)
			end

			local run = RF.start(global)

			-- any draw outside 1..numResponses would give a key beyond the range
			H.Engine.nextRandom = 99
			H.Engine.setRandom(1, n, k)
			RF.capture(run)

			local want = { "capture_phase_1_" .. k, "capture_phase_2_" .. k }

			lu.assertEquals(RF.keysOf(run, "capture_phase"), want, global .. ": capture taunts for a draw of " .. k .. " of " .. n)

			local ids = CS.sids("spacequest/" .. q.questType .. "/" .. q.questName)

			lu.assertNotNil(ids, global .. ": client string fixture")

			for _, key in ipairs(want) do
				lu.assertTrue(ids[key] == true, global .. ": '" .. key .. "' is in the pre-NGE client")
			end
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-3: the pay of the six recovery duties
---------------------------------------------------------------------------------------------

TestRecoveryFixesDutyPay = {}

function TestRecoveryFixesDutyPay:setUp() H.reset() end

function TestRecoveryFixesDutyPay:tearDown()
	DR.restoreRecoveryTables()
	H.Engine.config.rejectEmptyShipName = nil
end

local function assertPaidOnce(run, amount, label)
	local pay = RF.pay(run)

	lu.assertEquals(#pay.credits, 1, label .. ": addBankCredits calls")
	lu.assertEquals(pay.credits[1] and pay.credits[1].amount, amount, label .. ": credits")
	lu.assertEquals(pay.credits[1] and pay.credits[1].notify, true, label .. ": addBankCredits notify")
	lu.assertEquals(#pay.messages, 1, label .. ": @space/quest:recovery_reward messages")
	lu.assertEquals(pay.messages[1] and pay.messages[1].DI, amount, label .. ": recovery_reward DI")
	lu.assertFalse(pay.messages[1] ~= nil and pay.messages[1].plain, label .. ": recovery_reward is a string-id message with a DI parameter, not plain text")
end

local function assertNothingPaid(run, label)
	local pay = RF.pay(run)

	lu.assertEquals(#pay.credits, 0, label .. ": addBankCredits calls")
	lu.assertEquals(run.player.bankCredits, 0, label .. ": bank credits")
	lu.assertEquals(#pay.messages, 0, label .. ": @space/quest:recovery_reward messages")
	lu.assertEquals(RF.keys(run, ":rewardShips:"), {}, label .. ": :rewardShips: data left behind")
	lu.assertEquals(RF.keys(run, ":killsPending:"), {}, label .. ": :killsPending: data left behind")
end

for _, global in ipairs(DUTIES) do
	-- AC-3: one wave, all dead -> reward + bonus x n, paid once, with the message
	TestRecoveryFixesDutyPay["test_" .. global .. "_pays_reward_plus_bonus_per_ship_of_a_cleared_wave_once"] = function()
		local run = RF.start(global)
		local q = run.quest
		local n = #q.attackShips[1]

		RF.capture(run)

		local wave = RF.wave(run)

		lu.assertEquals(#wave, n, global .. ": the first wave has the ships of attack list 1")
		RF.killAll(run, wave)
		lu.assertEquals(readKey(run, ":rewardShips:"), n, global .. ": rewardShips after the wave is cleared")
		lu.assertEquals(readKey(run, ":killsPending:"), 0, global .. ": killsPending after the wave is cleared")
		lu.assertEquals(run.player.bankCredits, 0, global .. ": nothing is paid before the capture ends")

		RF.finish(run)
		assertPaidOnce(run, q.creditReward + q.creditKillBonus * n, global)
		lu.assertTrue(dutyEntryCleared(run), global .. ": the duty entry is cleared (re-takeable)")
		lu.assertEquals(RF.keys(run, ":rewardShips:"), {}, global .. ": :rewardShips: data after completion")
		lu.assertEquals(RF.keys(run, ":killsPending:"), {}, global .. ": :killsPending: data after completion")

		H.advance(60000)
		assertPaidOnce(run, q.creditReward + q.creditKillBonus * n, global .. " a minute later")
	end

	-- AC-3: no kills -> only the reward
	TestRecoveryFixesDutyPay["test_" .. global .. "_pays_only_the_reward_without_kills"] = function()
		local run = RF.start(global)

		RF.capture(run)
		RF.finish(run)
		assertPaidOnce(run, run.quest.creditReward, global)
		lu.assertTrue(dutyEntryCleared(run), global .. ": the duty entry is cleared")
	end

	-- AC-3 / AC-4: completeQuest on an entry that is already over pays nothing more
	TestRecoveryFixesDutyPay["test_" .. global .. "_does_not_pay_a_second_time_when_completed_again"] = function()
		local run = RF.start(global)

		RF.capture(run)
		RF.finish(run)
		run.quest:completeQuest(run.player, "true")
		H.advance(1000)
		assertPaidOnce(run, run.quest.creditReward, global)
	end

	-- AC-3 (cleared-set rule): kills in a set that is still partly alive at completion are not paid
	TestRecoveryFixesDutyPay["test_" .. global .. "_does_not_pay_kills_of_an_uncleared_set"] = function()
		local run = RF.start(global)
		local q = run.quest
		local a = #q.attackShips[1]

		RF.capture(run)
		RF.killAll(run, RF.wave(run))

		local later = RF.wave(run)

		lu.assertTrue(#later >= 2, global .. ": two more ships spawned")
		RF.kill(run, later[1])
		lu.assertEquals(readKey(run, ":rewardShips:"), a, global .. ": rewardShips counts the cleared first wave only")

		RF.finish(run)
		assertPaidOnce(run, q.creditReward + q.creditKillBonus * a, global)
	end

	-- AC-3: a failed, aborted, reset or abandoned duty pays nothing and leaves no pay data
	local function failures()
		return {
			{ "destroyed", function(run) H.destroyShip(run.ship, nil) H.advance(3000) end },
			{ "aborted", function(run) run.quest:abortQuest(run.player) H.advance(3000) end },
			{ "reset", function(run) run.quest:resetQuest(run.player) H.advance(3000) end },
			{ "left the zone", function(run) H.zoneSwitch(run.player, "space_tatooine") H.advance(3000) end },
		}
	end

	for _, how in ipairs({ "destroyed", "aborted", "reset", "left the zone" }) do
		TestRecoveryFixesDutyPay["test_" .. global .. "_pays_nothing_and_clears_the_pay_data_when_" .. how:gsub(" ", "_") .. "_after_kills"] = function()
			local run = RF.start(global)
			local q = run.quest
			local a = #q.attackShips[1]

			RF.capture(run)
			RF.killAll(run, RF.wave(run))

			local later = RF.wave(run)

			RF.kill(run, later[1])
			lu.assertEquals(readKey(run, ":rewardShips:"), a, global .. ": setup: rewardShips before the duty ends")
			lu.assertEquals(readKey(run, ":killsPending:"), 1, global .. ": setup: killsPending before the duty ends")

			for _, f in ipairs(failures()) do
				if f[1] == how then
					f[2](run)
				end
			end

			lu.assertFalse(DR.active(run.player, q), global .. ": the duty is over (" .. how .. ")")
			assertNothingPaid(run, global .. " " .. how)
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-4: the attack list survives a second wave (C-1c) and the cleared-set rule (C-2)
---------------------------------------------------------------------------------------------

TestRecoveryFixesAttackList = {}

function TestRecoveryFixesAttackList:setUp() H.reset() end

function TestRecoveryFixesAttackList:tearDown()
	DR.restoreRecoveryTables()
	H.Engine.config.rejectEmptyShipName = nil
end

local function idsOf(agents)
	local out = {}

	for i, a in ipairs(agents) do
		out[i] = a.objectID
	end

	return out
end

-- Two story recoveries have no attack waves or no escorts in their tables (recovery/naboo_privateer_tier3_1a.tab has no attack list,
-- recovery/corellia_rebel_tier3_1 spawns no escort); the wave and escort tests skip exactly these, and a pin test says so.
local WAVELESS = { recovery_naboo_privateer_tier3_1a = true }
local NO_ESCORTS = { recovery_corellia_rebel_tier3_1 = true }

-- The group wave n uses: the attack lists in order, wrapping around (SpaceRecoveryScreenplay:spawnAttackWave)
local function groupSize(q, n)
	return #q.attackShips[((n - 1) % #q.attackShips) + 1]
end

function TestRecoveryFixesAttackList:test_only_the_expected_quests_have_no_waves_or_no_escorts()
	for _, global in ipairs(sortedKeys(RF.EXPECTED)) do
		local q = H.expectGlobal(global, "recovery quest table")

		lu.assertEquals((q.attackDelay or 0) == 0 or #(q.attackShips or {}) == 0, WAVELESS[global] == true, global .. ": has no attack waves")
		lu.assertEquals(#(q.escortShips or {}) == 0, NO_ESCORTS[global] == true, global .. ": has no escorts")
	end
end

-- Two waves alive at once, the way the harness reaches it: two attack delays without a kill. Escorts are alive when wave 1 arrives.
local function twoWaves(run)
	local escorts = RF.escortIds(run)

	if not NO_ESCORTS[run.global] then
		lu.assertTrue(#escorts >= 1, run.global .. ": setup: escorts are alive after the capture")
	end

	local w1 = RF.wave(run)
	local w2 = RF.wave(run)

	return escorts, w1, w2
end

local WAVY = {}

for _, global in ipairs(sortedKeys(RF.EXPECTED)) do
	if not WAVELESS[global] then
		WAVY[#WAVY + 1] = global
	end
end

for _, global in ipairs(WAVY) do
	-- AC-4: wave 2 appends to the list, escorts stay in their own list
	TestRecoveryFixesAttackList["test_" .. global .. "_keeps_wave_1_in_the_attack_list_when_wave_2_spawns_and_leaves_the_escorts_alone"] = function()
		local run = RF.start(global)

		RF.capture(run)

		local escorts, w1, w2 = twoWaves(run)
		local want = idsOf(w1)

		for _, id in ipairs(idsOf(w2)) do
			want[#want + 1] = id
		end

		lu.assertTrue(#w1 >= 1 and #w2 >= 1, global .. ": both waves spawned ships")
		lu.assertEquals(RF.attackIds(run), want, global .. ": :attackShips: holds wave 1 then wave 2 and no escort")
		lu.assertEquals(RF.escortIds(run), escorts, global .. ": :spawnedShips: still holds the escorts")
	end

	-- AC-4: an escort death leaves the escort list, not the attack list, and is never counted
	if not NO_ESCORTS[global] then
		TestRecoveryFixesAttackList["test_" .. global .. "_does_not_count_an_escort_death_as_an_attack_ship"] = function()
			local run = RF.start(global)

			RF.capture(run)

			local escorts, w1, w2 = twoWaves(run)
			local before = RF.attackIds(run)

			RF.kill(run, getSceneObject(escorts[1]))
			lu.assertEquals(RF.attackIds(run), before, global .. ": :attackShips: after an escort died")

			local left = RF.escortIds(run)

			lu.assertEquals(#left, #escorts - 1, global .. ": :spawnedShips: after an escort died")
			lu.assertEquals(RF.count(left, escorts[1]), 0, global .. ": the dead escort left :spawnedShips:")
			lu.assertEquals(RF.count(RF.plainMessageKeys(run, "attack_stopped"), "attack_stopped"), 0, global .. ": no attack_stopped for an escort death")
		end
	end

	-- AC-4 (I-6): attack_stopped and the thanks taunt fire once, when the last outstanding attacker dies
	TestRecoveryFixesAttackList["test_" .. global .. "_sends_attack_stopped_and_thanks_once_when_the_last_outstanding_attacker_dies"] = function()
		local run = RF.start(global)

		RF.capture(run)

		local escorts, w1, w2 = twoWaves(run)

		RF.killAll(run, w2)
		lu.assertEquals(#RF.plainMessageKeys(run, "attack_stopped"), 0, global .. ": no attack_stopped while wave 1 is alive")
		lu.assertEquals(#RF.keysOf(run, "thanks_"), 0, global .. ": no thanks taunt while wave 1 is alive")

		for i = 1, #w1 - 1 do
			RF.kill(run, w1[i])
		end

		lu.assertEquals(#RF.plainMessageKeys(run, "attack_stopped"), 0, global .. ": no attack_stopped while one attacker is alive")

		RF.kill(run, w1[#w1])
		lu.assertEquals(RF.plainMessageKeys(run, "attack_stopped"), { "attack_stopped" }, global .. ": attack_stopped once, when the last attacker died")
		lu.assertEquals(#RF.keysOf(run, "thanks_"), 1, global .. ": one thanks taunt, when the last attacker died")
		lu.assertEquals(RF.attackIds(run), {}, global .. ": :attackShips: is empty")
		lu.assertEquals(#RF.escortIds(run), #escorts, global .. ": the escorts are untouched")
	end
end

for _, global in ipairs(DUTIES) do
	-- AC-4: reward ships = sizes of the cleared sets (here one set of a + b ships, cleared wave 2 first)
	TestRecoveryFixesAttackList["test_" .. global .. "_counts_a_plus_b_ships_when_wave_2_dies_first_and_then_wave_1"] = function()
		local run = RF.start(global)
		local q = run.quest

		RF.capture(run)

		local escorts, w1, w2 = twoWaves(run)
		local a, b = #w1, #w2

		lu.assertEquals({ a, b }, { groupSize(q, 1), groupSize(q, 2) }, global .. ": setup: wave sizes are the first two attack lists")

		-- escort deaths add nothing
		for _, id in ipairs(escorts) do
			RF.kill(run, getSceneObject(id))
		end

		lu.assertEquals({ readKey(run, ":rewardShips:"), readKey(run, ":killsPending:") }, { 0, 0 }, global .. ": rewardShips and killsPending after the escorts died")

		RF.killAll(run, w2)
		lu.assertEquals(readKey(run, ":rewardShips:"), 0, global .. ": rewardShips after wave 2 died, wave 1 alive")
		lu.assertEquals(readKey(run, ":killsPending:"), b, global .. ": killsPending after wave 2 died, wave 1 alive")

		RF.killAll(run, w1)
		lu.assertEquals(readKey(run, ":rewardShips:"), a + b, global .. ": rewardShips after both waves died")
		lu.assertEquals(readKey(run, ":killsPending:"), 0, global .. ": killsPending after both waves died")

		RF.finish(run)
		assertPaidOnce(run, q.creditReward + q.creditKillBonus * (a + b), global)
	end
end

---------------------------------------------------------------------------------------------
-- C-1b: the onAttackShipKilled hook
---------------------------------------------------------------------------------------------

TestRecoveryFixesKillHook = {}

function TestRecoveryFixesKillHook:setUp() H.reset() end

function TestRecoveryFixesKillHook:tearDown()
	DR.restoreRecoveryTables()
	H.Engine.config.rejectEmptyShipName = nil
end

-- C-1b: the base hook exists and does nothing
function TestRecoveryFixesKillHook:test_the_base_hook_is_a_no_op_function()
	lu.assertEquals(type(SpaceRecoveryScreenplay.onAttackShipKilled), "function", "SpaceRecoveryScreenplay.onAttackShipKilled")
	lu.assertNil(SpaceRecoveryScreenplay:onAttackShipKilled(nil, 0), "result of the base hook")
end

-- C-1b: once per destroyed attack ship, after the ship left the list and before the messages
function TestRecoveryFixesKillHook:test_the_hook_runs_once_per_attack_ship_after_the_list_update_and_before_the_messages()
	local run = RF.start("recovery_corellia_privateer_tier3_1")
	local q = run.quest

	RF.capture(run)

	local wave = RF.wave(run)
	local n = #wave
	local calls = H.spyOn(q, "onAttackShipKilled", function(self, pPlayer, remaining)
		return { listed = #RF.attackIds(run), messages = #H.messageLog(run.player), remaining = remaining }
	end)

	lu.assertTrue(n >= 2, "setup: the wave has at least two ships")

	for i, agent in ipairs(wave) do
		local messagesBefore = #H.messageLog(run.player)

		RF.kill(run, agent)
		lu.assertEquals(#calls, i, "hook calls after kill " .. i)
		lu.assertEquals(calls[i].args[1], run.player, "hook player argument of kill " .. i)
		lu.assertEquals(calls[i].args[2], n - i, "remaining ships given to the hook by kill " .. i)
		lu.assertEquals(calls[i].snapshot.listed, n - i, "ships in :attackShips: when the hook ran for kill " .. i)
		lu.assertEquals(calls[i].snapshot.messages, messagesBefore, "messages sent before the hook ran for kill " .. i)
	end
end

-- C-1b: not called on the early-return paths
function TestRecoveryFixesKillHook:test_the_hook_is_not_called_for_a_missing_ship_or_a_missing_recovery_ship()
	local run = RF.start("recovery_corellia_privateer_tier3_1")
	local q = run.quest

	RF.capture(run)

	local wave = RF.wave(run)
	local calls = H.spyOn(q, "onAttackShipKilled")

	lu.assertEquals(q:notifyAttackShipDestroyed(nil, nil), 1, "notifyAttackShipDestroyed(nil) result")
	lu.assertEquals(#calls, 0, "hook calls for a missing ship")

	deleteData(RF.key(run, ":recoveryShip:"))
	RF.kill(run, wave[1])
	lu.assertEquals(#calls, 0, "hook calls when the recovery ship is gone")
end

---------------------------------------------------------------------------------------------
-- C-2: the duty pays reward + bonus x ships, with the numbers of the two tiers (AC-3)
---------------------------------------------------------------------------------------------

TestRecoveryFixesPayAmounts = {}

function TestRecoveryFixesPayAmounts:setUp() H.reset() end

function TestRecoveryFixesPayAmounts:tearDown()
	DR.restoreRecoveryTables()
	H.Engine.config.rejectEmptyShipName = nil
end

-- AC-3: tier 2 CorSec duty 12 with a wave of two blastboats: 2500 + 200 x 2 = 2900 (spec Data mapping section 2)
function TestRecoveryFixesPayAmounts:test_corsec_duty_12_pays_2900_for_its_first_wave()
	local run = RF.start("recovery_duty_corellia_privateer_12")

	RF.capture(run)
	RF.killAll(run, RF.wave(run))
	RF.finish(run)
	assertPaidOnce(run, 2900, "recovery_duty_corellia_privateer_12")
end

-- AC-3: tier 4 CorSec duty with a wave of four ships: 5000 + 300 x 4 = 6200
function TestRecoveryFixesPayAmounts:test_corsec_tier_4_duty_pays_6200_for_its_first_wave()
	local run = RF.start("recovery_duty_corellia_privateer_tier4_1")

	RF.capture(run)
	RF.killAll(run, RF.wave(run))
	RF.finish(run)
	assertPaidOnce(run, 6200, "recovery_duty_corellia_privateer_tier4_1")
end
