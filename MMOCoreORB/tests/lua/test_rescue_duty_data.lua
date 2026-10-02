-- Duty rescue quest data conformance and class contract (space-quest-rescue-duty).
-- Spec: .claude/work/space-quest-rescue-duty/01-spec.md (AC-1, I-2, I-3, Content contract, Data mapping).
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/rescue_duty/ plus the patrol point files,
-- never the Core3 tables under test.

local lu = require("luaunit")
local H = require("harness")
local DR = require("rescue_duty_scenario")

DR.load()

local function quest(name)
	return H.expectGlobal(DR.global(name), "duty rescue quest table for " .. name)
end

local function label(name) return "rescue_duty/" .. name end

local function dutyGlobals()
	local out = {}

	for _, n in ipairs(H.questGlobals()) do
		if rawget(_G, n).questType == "rescue_duty" and rawget(_G, n).questName ~= "" then
			out[#out + 1] = n
		end
	end

	return out
end

TestRescueDutyDataConformance = {}

function TestRescueDutyDataConformance:setUp() H.reset() end

-- AC-1
function TestRescueDutyDataConformance:test_the_fixtures_carry_the_values_the_spec_table_lists()
	local want = {
		corellia_privateer_tier4_1 = { "space_dantooine", 1, 10, 90, 1, 3, 3, 5, 5000, 300 },
		corellia_rebel_tier4_1 = { "space_dantooine", 7, 3, 60, 1, 5, 3, 5, 5000, 300 },
	}

	for _, name in ipairs(DR.NAMES) do
		local o = DR.oracle(name)

		lu.assertEquals({ o.zone, #o.targetShips, o.arrivalDelay, o.period, o.listType, o.responses, o.listCount, #o.path, o.reward, o.killReward }, want[name],
			label(name) .. ": {zone, targets, arrival delay, period, list type, responses, lists, path points, reward, killReward} in the fixture")
	end

	lu.assertEquals(#DR.oracle("corellia_rebel_tier4_1").lists[1], 4, "rebel list 1 has 4 ships (the 4th row of the .tab)")
	lu.assertEquals(DR.oracle("corellia_rebel_tier4_1").lists[2], { "imp_lambda_shuttle_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4" }, "rebel list 2")
	lu.assertEquals(DR.oracle("corellia_privateer_tier4_1").lists[1], { "hutt_pirate_s02_tier4", "hutt_pirate_s02_tier4", "hutt_pirate_s02_tier4", "hutt_pirate_s02_tier4" }, "privateer list 1")
end

-- AC-1
function TestRescueDutyDataConformance:test_zone_delay_period_list_type_responses_and_rewards_equal_the_tab()
	for _, name in ipairs(DR.NAMES) do
		local o = DR.oracle(name)
		local t = quest(name)

		lu.assertEquals(t.questZone, o.zone, label(name) .. ": questZone")
		lu.assertEquals(t.questZone, "space_dantooine", label(name) .. ": questZone is Dantooine for both duties")
		lu.assertEquals(t.targetArrivalDelay, o.arrivalDelay, label(name) .. ": targetArrivalDelay")
		lu.assertEquals(t.attackPeriod, o.period, label(name) .. ": attackPeriod")
		lu.assertEquals(t.attackListType, o.listType, label(name) .. ": attackListType (sequential=0, random=1)")
		lu.assertEquals(t.numResponses, o.responses, label(name) .. ": numResponses")
		lu.assertEquals(t.creditReward, o.reward, label(name) .. ": creditReward = .tab reward")
		lu.assertEquals(t.creditKillBonus, o.killReward, label(name) .. ": creditKillBonus = .tab killReward")
	end
end

-- AC-1
function TestRescueDutyDataConformance:test_target_ship_types_are_the_non_empty_tab_rows_in_order()
	for _, name in ipairs(DR.NAMES) do
		local o = DR.oracle(name)
		local t = quest(name)

		lu.assertEquals(type(t.targetShipTypes), "table", label(name) .. ": targetShipTypes must be a table")
		lu.assertEquals(t.targetShipTypes, o.targetShips, label(name) .. ": targetShipTypes")
	end
end

-- AC-1
function TestRescueDutyDataConformance:test_recovery_path_has_the_tab_points_in_order_unrotated_with_patrol_point_coordinates()
	for _, name in ipairs(DR.NAMES) do
		local o = DR.oracle(name)
		local path = quest(name).recoveryPath

		lu.assertEquals(type(path), "table", label(name) .. ": recoveryPath must be a table")
		lu.assertEquals(#path, #o.path, label(name) .. ": number of recoveryPath points")

		for i, p in ipairs(o.path) do
			lu.assertEquals(type(path[i]), "table", label(name) .. ": recoveryPath[" .. i .. "] must be a table, not a 'zone:name' string")
			lu.assertEquals(path[i].patrolPointName, p.name, label(name) .. ": recoveryPath[" .. i .. "].patrolPointName")
			lu.assertEquals(p.zone, quest(name).questZone, label(name) .. ": the .tab's point zone equals questZone (point " .. i .. ")")
			lu.assertEquals(path[i].x, p.x, label(name) .. ": recoveryPath[" .. i .. "].x")
			lu.assertEquals(path[i].z, p.z, label(name) .. ": recoveryPath[" .. i .. "].z")
			lu.assertEquals(path[i].y, p.y, label(name) .. ": recoveryPath[" .. i .. "].y")
		end
	end
end

-- AC-1
function TestRescueDutyDataConformance:test_attack_lists_are_the_tab_columns_not_rows()
	for _, name in ipairs(DR.NAMES) do
		local o = DR.oracle(name)
		local t = quest(name)

		lu.assertEquals(type(t.attackShipLists), "table", label(name) .. ": attackShipLists must be a table")
		lu.assertEquals(#t.attackShipLists, o.listCount, label(name) .. ": number of attack lists (numAttackShipLists)")

		for i, list in ipairs(o.lists) do
			lu.assertEquals(t.attackShipLists[i], list, label(name) .. ": attackShipLists[" .. i .. "] (column attackShips" .. i .. " of the .tab)")
		end
	end
end

-- AC-1
function TestRescueDutyDataConformance:test_the_trainers_still_name_these_duty_quests()
	local corsec = H.expectGlobal("CorsecSquadronScreenplay", "CorSec squadron screenplay")
	local havoc = H.expectGlobal("HavocSquadronScreenplay", "Havoc squadron screenplay")

	lu.assertEquals(corsec.TIER4_QUEST_STRING_DUTY_2, { type = "rescue_duty", name = "corellia_privateer_tier4_1" }, "CorSec TIER4_QUEST_STRING_DUTY_2")
	lu.assertEquals(havoc.TIER4_QUEST_STRING_DUTY_2, { type = "rescue_duty", name = "corellia_rebel_tier4_1" }, "Havoc TIER4_QUEST_STRING_DUTY_2")
end

TestRescueDutyDataInvariants = {}

function TestRescueDutyDataInvariants:setUp() H.reset() end

-- I-2
function TestRescueDutyDataInvariants:test_there_are_exactly_the_three_duty_rescue_quests()
	lu.assertEquals(dutyGlobals(), { "rescue_duty_corellia_privateer_tier4_1", "rescue_duty_corellia_rebel_tier4_1", "rescue_duty_naboo_privateer_tier4_1" }, "rescue_duty quest globals")
end

-- I-2
function TestRescueDutyDataInvariants:test_no_duty_rescue_quest_keeps_a_legacy_key()
	for _, n in ipairs(dutyGlobals()) do
		for _, key in ipairs(DR.LEGACY_KEYS) do
			lu.assertNil(rawget(rawget(_G, n), key), n .. ": raw legacy key '" .. key .. "' must be gone")
		end
	end
end

-- I-2
function TestRescueDutyDataInvariants:test_recovery_path_and_target_ship_types_are_non_empty_on_every_duty_rescue_quest()
	for _, n in ipairs(dutyGlobals()) do
		local q = rawget(_G, n)

		lu.assertEquals(type(q.recoveryPath), "table", n .. ": recoveryPath")
		lu.assertTrue(#q.recoveryPath > 0, n .. ": recoveryPath is not empty")
		lu.assertEquals(type(q.targetShipTypes), "table", n .. ": targetShipTypes")
		lu.assertTrue(#q.targetShipTypes > 0, n .. ": targetShipTypes is not empty")

		for i, p in ipairs(q.recoveryPath) do
			lu.assertEquals(type(p.patrolPointName), "string", n .. ": recoveryPath[" .. i .. "].patrolPointName")
			lu.assertEquals(type(p.x) .. type(p.z) .. type(p.y), "numbernumbernumber", n .. ": recoveryPath[" .. i .. "] coordinates")
		end
	end
end

-- I-3
function TestRescueDutyDataInvariants:test_every_target_and_attack_ship_has_a_ship_template()
	for _, name in ipairs(DR.NAMES) do
		local t = quest(name)
		local names = {}

		lu.assertEquals(type(t.targetShipTypes), "table", label(name) .. ": targetShipTypes must be a table")
		lu.assertEquals(type(t.attackShipLists), "table", label(name) .. ": attackShipLists must be a table")

		for _, ship in ipairs(t.targetShipTypes) do
			names[#names + 1] = ship
		end

		for _, list in ipairs(t.attackShipLists) do
			for _, ship in ipairs(list) do
				names[#names + 1] = ship
			end
		end

		lu.assertTrue(#names > 0, label(name) .. ": there are ships to check")

		for _, ship in ipairs(names) do
			lu.assertEquals(type(ship), "string", label(name) .. ": ship name")
			lu.assertTrue(H.fileExists(H.SCRIPTS .. "ship_mobile/ships/" .. ship .. ".lua"), label(name) .. ": ship template bin/scripts/ship_mobile/ships/" .. tostring(ship) .. ".lua must exist")
		end
	end
end

-- Content contract: untouched identity and wiring
function TestRescueDutyDataInvariants:test_identity_split_wiring_and_registration_are_unchanged()
	for _, name in ipairs(DR.NAMES) do
		local t = quest(name)

		lu.assertEquals({ t.className, t.questName, t.questType }, { DR.global(name), name, "rescue_duty" }, label(name) .. ": className, questName, questType")
		lu.assertEquals({ t.sideQuest, t.sideQuestType }, { false, "" }, label(name) .. ": no side quest")
		lu.assertEquals(H.registered(DR.global(name)) and H.registered(DR.global(name)).start, true, label(name) .. ": registerScreenPlay(name, true)")
		lu.assertEquals(t.parentQuest or "", "", label(name) .. ": no parent quest")
	end
end

TestRescueDutyClassContract = {}

function TestRescueDutyClassContract:setUp() H.reset() end

local function class()
	return H.expectGlobal("SpaceDutyRescueScreenplay", "screenplays/space/SpaceDutyRescueScreenplay.lua")
end

-- Content contract: the table and its identity
function TestRescueDutyClassContract:test_the_class_is_a_rescue_subclass_with_its_own_name_and_type()
	local c = class()

	lu.assertEquals(c.className, "SpaceDutyRescueScreenplay", "className")
	lu.assertEquals(c.questType, "rescue_duty", "questType")
	lu.assertEquals(H.registered("SpaceDutyRescueScreenplay") and H.registered("SpaceDutyRescueScreenplay").start, false, "registerScreenPlay(\"SpaceDutyRescueScreenplay\", false)")
	lu.assertEquals(c.STAGES, SpaceRescueScreenplay.STAGES, "the stages are the rescue class's (inherited)")
	lu.assertEquals(type(c.start), "function", "start exists (empty)")
end

-- Content contract: new class fields and their defaults
function TestRescueDutyClassContract:test_the_new_fields_have_their_defaults_on_the_class()
	local c = class()

	lu.assertEquals(rawget(c, "targetShipTypes"), {}, "targetShipTypes default")
	lu.assertEquals(rawget(c, "creditKillBonus"), 0, "creditKillBonus default")
	lu.assertEquals(rawget(c, "cycleCleanupDelay"), 2, "cycleCleanupDelay (RD:162 cleanupShipsMsg, seconds)")
	lu.assertEquals(rawget(c, "nextCycleDelay"), 10, "nextCycleDelay (RD:179, seconds)")
end

-- Content contract: overrides and new methods are the duty's own; completePhraseKey and the mixin are inherited
function TestRescueDutyClassContract:test_the_duty_overrides_the_listed_hooks_and_inherits_the_rest()
	local c = class()

	for _, m in ipairs({ "pathPoints", "pickTargetShip", "capturePhraseKey", "shouldSendInProgress", "onRescueArrived", "notifyAttackShipKilled", "enteredZone",
		"abandonRun", "failQuest", "cleanUpQuestData", "endDuty", "endCycle", "nextCycle", "releaseCycle" }) do
		lu.assertEquals(type(rawget(c, m)), "function", "SpaceDutyRescueScreenplay." .. m .. " is defined on the duty class")
	end

	lu.assertNil(rawget(c, "completePhraseKey"), "completePhraseKey is not overridden (RD:159, the literal 'complete')")
	lu.assertNil(rawget(c, "launchWave"), "the duty does not call mixInto again (the wave functions are inherited)")
	lu.assertEquals(c.launchWave, SpaceRescueScreenplay.launchWave, "launchWave comes from SpaceRescueScreenplay")
	lu.assertEquals(c.startQuest, SpaceRescueScreenplay.startQuest, "startQuest is inherited")
end

-- Content contract: the data fields the quests use are read through the inherited path
function TestRescueDutyClassContract:test_a_duty_quest_keeps_the_literal_complete_phrase_and_sends_progress_at_cycle_zero()
	local q = quest(DR.REP)

	lu.assertEquals(type(q.shouldSendInProgress), "function", "shouldSendInProgress exists on the duty")
	lu.assertEquals(q:completePhraseKey(1), "complete", "completePhraseKey")
	lu.assertEquals(q:shouldSendInProgress(1), true, "shouldSendInProgress is true while cycle == 0")
end
