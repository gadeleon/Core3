-- Rescue quest data conformance (space-quest-rescue-docking).
-- Spec: .claude/work/space-quest-rescue-docking/01-spec.md (AC-1, I-2, I-3, Content contract: class
-- constants and data fields, Data mapping). The oracle is the SWG-Source .tab copies in
-- fixtures/spacequest/rescue/ plus the patrol point files, never the Core3 tables under test.

local lu = require("luaunit")
local H = require("harness")
local R = require("rescue_scenario")

R.load()

local function quest(name)
	return H.expectGlobal(R.global(name), "rescue quest table for " .. name)
end

local function label(name) return "rescue/" .. name end

local LEGACY_KEYS = { "rescueShip", "rescueLocation", "rescuePoints", "rescueArrivalDelay", "arrivalDelay", "repairDelay", "escortPoints",
	"escortSpeed", "escortAttackDelay", "escortAttackShips", "attackDelay", "attackShips", "tauntData" }

local function rescueGlobals()
	local out = {}

	for _, n in ipairs(H.questGlobals()) do
		if rawget(_G, n).questType == "rescue" and rawget(_G, n).questName ~= "" then
			out[#out + 1] = n
		end
	end

	return out
end

TestRescueDataConformance = {}

function TestRescueDataConformance:setUp() H.reset() end

-- AC-1
function TestRescueDataConformance:test_zone_target_delay_period_and_responses_equal_the_tab()
	for _, name in ipairs(R.NAMES) do
		local o = R.oracle(name)
		local t = quest(name)

		lu.assertEquals(t.questZone, o.zone, label(name) .. ": questZone")
		lu.assertEquals(t.targetShipType, o.targetShip, label(name) .. ": targetShipType")
		lu.assertEquals(t.targetArrivalDelay, o.arrivalDelay, label(name) .. ": targetArrivalDelay")
		lu.assertEquals(t.attackPeriod, o.period, label(name) .. ": attackPeriod")
		lu.assertEquals(t.attackListType, o.listType, label(name) .. ": attackListType (sequential=0, random=1)")
		lu.assertEquals(t.numResponses, o.responses, label(name) .. ": numResponses")
	end
end

-- AC-1
function TestRescueDataConformance:test_recovery_path_has_the_tab_points_in_order_with_patrol_point_coordinates()
	for _, name in ipairs(R.NAMES) do
		local o = R.oracle(name)
		local path = quest(name).recoveryPath

		lu.assertEquals(type(path), "table", label(name) .. ": recoveryPath must be a table")
		lu.assertEquals(#path, #o.path, label(name) .. ": number of recoveryPath points")

		for i, p in ipairs(o.path) do
			lu.assertEquals(type(path[i]), "table", label(name) .. ": recoveryPath[" .. i .. "] must be a table, not a 'zone:name' string")
			lu.assertEquals(path[i].patrolPointName, p.name, label(name) .. ": recoveryPath[" .. i .. "].patrolPointName")
			lu.assertEquals(p.zone, o.zone, label(name) .. ": the .tab's point zone equals questZone (point " .. i .. ")")
			lu.assertEquals(path[i].x, p.x, label(name) .. ": recoveryPath[" .. i .. "].x")
			lu.assertEquals(path[i].z, p.z, label(name) .. ": recoveryPath[" .. i .. "].z")
			lu.assertEquals(path[i].y, p.y, label(name) .. ": recoveryPath[" .. i .. "].y")
		end
	end
end

-- AC-1
function TestRescueDataConformance:test_attack_lists_are_the_tab_columns_not_rows()
	for _, name in ipairs(R.NAMES) do
		local o = R.oracle(name)
		local t = quest(name)

		lu.assertEquals(type(t.attackShipLists), "table", label(name) .. ": attackShipLists must be a table")
		lu.assertEquals(#t.attackShipLists, o.listCount, label(name) .. ": number of attack lists (numAttackShipLists)")

		for i, list in ipairs(o.lists) do
			lu.assertEquals(t.attackShipLists[i], list, label(name) .. ": attackShipLists[" .. i .. "] (column attackShips" .. i .. " of the .tab)")
		end
	end
end

-- AC-1, the oracle itself (guards against a fixture that parsed into something unexpected)
function TestRescueDataConformance:test_the_fixtures_carry_the_values_the_spec_table_lists()
	local want = {
		naboo_privateer_tier3_2e = { "space_corellia", "madersim_tier3", 0, 110, 0, 3, 4, 4 },
		corellia_rebel_tier4_2_b = { "space_dathomir", "reb_diplomat_tier4", 3, 50, 1, 5, 3, 4 },
		corellia_rebel_tier4_4_b = { "space_endor", "spynet_spy_tier4", 5, 50, 1, 5, 3, 6 },
	}

	for _, name in ipairs(R.NAMES) do
		local o = R.oracle(name)

		lu.assertEquals({ o.zone, o.targetShip, o.arrivalDelay, o.period, o.listType, o.responses, o.listCount, #o.path }, want[name],
			label(name) .. ": {zone, target, arrival delay, period, list type, responses, lists, path points} in the fixture")
	end

	lu.assertEquals(R.oracle("naboo_privateer_tier3_2e").lists[4], { "aynat_vaporizer_tier3", "aynat_vaporizer_tier3", "aynat_viggo_tier2" }, "2e list 4")
	lu.assertEquals(#R.oracle("corellia_rebel_tier4_2_b").lists[1], 6, "2_b lists have 6 ships")
end

TestRescueDataInvariants = {}

function TestRescueDataInvariants:setUp() H.reset() end

-- I-2
function TestRescueDataInvariants:test_there_are_exactly_the_three_rescue_quests()
	local expected = {}

	for _, name in ipairs(R.NAMES) do
		expected[#expected + 1] = R.global(name)
	end

	table.sort(expected)

	lu.assertEquals(rescueGlobals(), expected, "rescue quest globals (the duty rescues are questType rescue_duty and are not part of this slice)")
end

-- I-2
function TestRescueDataInvariants:test_no_rescue_quest_keeps_a_legacy_key()
	for _, n in ipairs(rescueGlobals()) do
		for _, key in ipairs(LEGACY_KEYS) do
			lu.assertNil(rawget(rawget(_G, n), key), n .. ": raw legacy key '" .. key .. "' must be gone")
		end
	end
end

-- I-2
function TestRescueDataInvariants:test_recovery_path_is_a_non_empty_table_of_point_tables_on_every_rescue_quest()
	for _, n in ipairs(rescueGlobals()) do
		local path = rawget(_G, n).recoveryPath

		lu.assertEquals(type(path), "table", n .. ": recoveryPath")
		lu.assertTrue(#path > 0, n .. ": recoveryPath is not empty")

		for i, p in ipairs(path) do
			lu.assertEquals(type(p), "table", n .. ": recoveryPath[" .. i .. "] is a table")
			lu.assertEquals(type(p.patrolPointName), "string", n .. ": recoveryPath[" .. i .. "].patrolPointName")
			lu.assertEquals(type(p.x) .. type(p.z) .. type(p.y), "numbernumbernumber", n .. ": recoveryPath[" .. i .. "] coordinates")
		end
	end
end

-- I-2, untouched wiring (Data mapping: autoReward/questDelay/trigger* are not touched; Scope: rewards and
-- split wiring stay exactly as they are)
function TestRescueDataInvariants:test_parent_and_side_quest_wiring_and_rewards_are_unchanged()
	local rsf = quest("naboo_privateer_tier3_2e")
	local b2 = quest("corellia_rebel_tier4_2_b")
	local b4 = quest("corellia_rebel_tier4_4_b")

	lu.assertEquals({ rsf.parentQuest, rsf.sideQuest, rsf.creditReward }, { "space_battle_naboo_privateer_tier3_2d", false, 25000 }, "2e: parent, sideQuest, creditReward")
	lu.assertEquals({ b2.parentQuest, b2.sideQuest, b2.creditReward }, { "assassinate_corellia_rebel_tier4_2", false, 0 }, "2_b: parent, sideQuest, creditReward")
	lu.assertEquals({ b4.parentQuest, b4.sideQuest, b4.sideQuestType, b4.sideQuestName, b4.sideQuestSplitType, b4.sideQuestDelay },
		{ "recovery_corellia_rebel_tier4_4", true, "assassinate", "corellia_rebel_tier4_4_a", SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION, 0 },
		"4_b: parent and completion split wiring")
end

-- Content contract: registration
function TestRescueDataInvariants:test_every_rescue_quest_and_the_class_stay_registered()
	for _, name in ipairs(R.NAMES) do
		lu.assertEquals(H.registered(R.global(name)) and H.registered(R.global(name)).start, true, R.global(name) .. ": registerScreenPlay(name, true)")
	end

	lu.assertNotNil(H.registered("SpaceRescueScreenplay"), "SpaceRescueScreenplay registered")
	lu.assertEquals(H.registered("SpaceRescueScreenplay").start, false, "SpaceRescueScreenplay is registered with start = false")
end

-- I-3
function TestRescueDataInvariants:test_every_target_and_attack_ship_has_a_ship_template()
	for _, name in ipairs(R.NAMES) do
		local t = quest(name)
		local names = { t.targetShipType }

		lu.assertEquals(type(t.attackShipLists), "table", label(name) .. ": attackShipLists must be a table")

		for _, list in ipairs(t.attackShipLists) do
			for _, ship in ipairs(list) do
				names[#names + 1] = ship
			end
		end

		for _, ship in ipairs(names) do
			lu.assertEquals(type(ship), "string", label(name) .. ": ship name")
			lu.assertTrue(H.fileExists(H.SCRIPTS .. "ship_mobile/ships/" .. ship .. ".lua"), label(name) .. ": ship template bin/scripts/ship_mobile/ships/" .. tostring(ship) .. ".lua must exist")
		end
	end
end

TestRescueClassContract = {}

function TestRescueClassContract:setUp() H.reset() end

local function needMethods(q, names)
	for _, m in ipairs(names) do
		lu.assertEquals(type(q[m]), "function", "expected the rewritten SpaceRescueScreenplay to define " .. m)
	end
end

local function class()
	return H.expectGlobal("SpaceRescueScreenplay", "screenplays/space/SpaceRescueScreenplay.lua")
end

-- Content contract: class identity and enums
function TestRescueClassContract:test_the_class_names_itself_and_defines_the_enums()
	local c = class()

	lu.assertEquals(c.className, "SpaceRescueScreenplay", "className")
	lu.assertEquals(c.questType, "rescue", "questType")
	lu.assertEquals(c.ATTACK_LIST_TYPES, { SEQUENTIAL = 0, RANDOM = 1 }, "ATTACK_LIST_TYPES")
	lu.assertEquals(c.STAGES, { WARP = 1, DOCK = 2, DOCKED = 3, ESCORT = 4, ARRIVED = 5 }, "STAGES")
end

-- Content contract: constants, each with its source
function TestRescueClassContract:test_the_tuning_constants_are_readable_on_the_class()
	local c = class()
	local want = {
		arrivalRadius = 300, setupCheckDelay = 1, targetSpawnMinDistance = 100, targetSpawnMaxDistance = 200,
		waypointFirstDelay = 1, waypointRefreshPeriod = 30, escortStartDelay = 10, finishDelay = 3, targetLifetime = 3600,
		escortSpeed = 50, repairAmount = 1, maxActiveWaves = 2, spawnMinDistance = 1000, spawnMaxDistance = 1200,
		spawnSpread = 150, squadronMinSize = 4,
	}

	for key, value in pairs(want) do
		lu.assertEquals(c[key], value, "SpaceRescueScreenplay." .. key)
	end
end

-- Content contract: per-quest data defaults on the class
function TestRescueClassContract:test_the_data_fields_have_empty_defaults_on_the_class()
	local c = class()

	lu.assertEquals(c.recoveryPath, {}, "recoveryPath default")
	lu.assertEquals(c.targetShipType, "", "targetShipType default")
	lu.assertEquals(c.targetArrivalDelay, 0, "targetArrivalDelay default")
	lu.assertEquals(c.attackShipLists, {}, "attackShipLists default")
	lu.assertEquals(c.attackPeriod, 0, "attackPeriod default")
	lu.assertEquals(c.attackListType, 0, "attackListType default")
	lu.assertEquals(c.numResponses, 0, "numResponses default")
end

-- Content contract: public methods tests call
function TestRescueClassContract:test_the_public_methods_exist()
	local c = class()

	for _, m in ipairs({ "startQuest", "completeQuest", "failQuest", "resetQuest", "cleanUpQuestData", "enteredZone", "checkSetup", "notifyEnteredQuestArea",
		"notifyDocked", "notifyTargetDestroyed", "notifyAttackShipDestroyed", "launchWave", "removeAttackShips", "cleanUpWaveData", "dataKey",
		"messagePath", "isCurrentRun", "getRunToken", "getWaveAnchor", "notifyWaveLaunched", "notifyWavesCleared", "notifyTargetsRemaining",
		"pathPoints", "pickTargetShip", "capturePhraseKey", "completePhraseKey", "onRescueArrived" }) do
		lu.assertEquals(type(c[m]), "function", "SpaceRescueScreenplay:" .. m)
	end
end

-- Content contract: extension points for slice 2
function TestRescueClassContract:test_the_extension_points_return_the_base_values()
	local c = class()
	local quest = quest(R.REP)

	needMethods(quest, { "pathPoints", "pickTargetShip", "capturePhraseKey", "completePhraseKey" })
	lu.assertEquals(quest:pathPoints(1234), quest.recoveryPath, "pathPoints returns self.recoveryPath")
	lu.assertEquals(quest:pickTargetShip(1234), quest.targetShipType, "pickTargetShip returns self.targetShipType")
	lu.assertEquals(quest:capturePhraseKey(1234), "rescue_phase_2", "capturePhraseKey")
	lu.assertEquals(quest:completePhraseKey(1234), "complete", "completePhraseKey")
	lu.assertEquals(type(c.onRescueArrived), "function", "onRescueArrived")
end

-- Content contract: key and message shapes
function TestRescueClassContract:test_key_and_message_helpers_have_the_delivery_shapes()
	local q = quest(R.REP)

	needMethods(q, { "dataKey", "messagePath", "isCurrentRun" })
	lu.assertEquals(q:dataKey(77, "stage"), "77:rescue_corellia_rebel_tier4_2_b:stage", "dataKey")
	lu.assertEquals(q:messagePath("thanks_2"), "@spacequest/rescue/corellia_rebel_tier4_2_b:thanks_2", "messagePath")
	lu.assertFalse(q:isCurrentRun(nil, "5"), "isCurrentRun(nil)")
end

-- Content contract: the class keeps the mixin contract and the start hook
function TestRescueClassContract:test_start_is_empty_and_the_mixin_is_mixed_in()
	local c = class()

	lu.assertEquals(type(c.start), "function", "start")
	lu.assertEquals(rawget(c, "launchWave"), SpaceAttackWaves.launchWave, "launchWave is the mixin's raw function")
end
