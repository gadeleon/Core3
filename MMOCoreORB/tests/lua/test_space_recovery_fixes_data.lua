-- Space recovery and recovery-duty fixes, data: CorSec recovery duty 12 rebuilt from SWG-Source, the pay fields of the six recovery duties,
-- the Havoc spawn keys and the client strings the new content needs.
-- Spec: .claude/work/space-recovery-duty-fixes/01-spec.md (AC-6, AC-9, AC-10, Content contract C-3, C-4, Data mapping 1 to 3, invariants I-2, I-5, I-7).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/recovery_duty/ (byte copies, CRLF) and the patrol point files, never the
-- tables under test. The spec's literals are repeated as anchors, so a misparsed fixture cannot make a wrong table look right.

local lu = require("luaunit")
local H = require("harness")
local RF = require("recovery_fixes_scenario")
local CS = require("harness.client_strings")

RF.load()

local DUTY12 = "recovery_duty_corellia_privateer_12"

local function readFile(path)
	local f = assert(io.open(path, "rb"), "cannot open " .. path)
	local text = f:read("a")

	f:close()
	return text
end

local function sortedKeys(t)
	local out = {}

	for k in pairs(t) do
		out[#out + 1] = k
	end

	table.sort(out)
	return out
end

local function reaches(q, class)
	local mt = getmetatable(q)

	for _ = 1, 10 do
		if mt == nil then
			return false
		end

		if mt == class then
			return true
		end

		mt = getmetatable(mt)
	end

	return false
end

local function duty12() return H.expectGlobal(DUTY12, "CorSec recovery duty 12 quest table (space-recovery-duty-fixes C-3)") end

-- numbered points of a fixture path column, as the Core3 table lists them
local function numbered(rec, column)
	local out = {}

	for i, value in ipairs(rec:list(column)) do
		local zone, name = H.Tab.splitNavPoint(value)
		local p = H.patrolPoints(zone)[name]

		assert(p ~= nil, "patrol point " .. tostring(name) .. " not found in " .. tostring(zone))
		out[i] = { patrolPointName = name, x = p.x, z = p.z, y = p.y, escortNumber = i, radius = 250 }
	end

	return out
end

local function attackLists(rec)
	local lists = {}

	for i = 1, rec:num("numAttackShipLists") do
		lists[i] = rec:list("attackShips" .. i)
	end

	return lists
end

---------------------------------------------------------------------------------------------
-- AC-6: recovery_duty_corellia_privateer_12 equals SWG's table
---------------------------------------------------------------------------------------------

TestRecoveryDuty12 = {}

function TestRecoveryDuty12:setUp() H.reset() end

-- AC-6: the fixture is the SWG file (CRLF, five data rows) and the parse matches the spec's anchors
function TestRecoveryDuty12:test_the_fixture_is_the_swg_file_and_parses_to_the_spec_values()
	local text = readFile(H.FIXTURES .. "spacequest/recovery_duty/corellia_privateer_12.tab")
	local rec = H.questFixture("recovery_duty", "corellia_privateer_12")

	lu.assertNotNil(text:find("\r\n", 1, true), "the fixture keeps SWG's CRLF line ends")
	lu.assertEquals({ rec:get("questZone"), rec:num("targetArrivalDelay"), rec:num("targetRecoverTime"), rec:num("numAttackShipLists"), rec:num("attackPeriod"), rec:num("numResponses"), rec:num("reward"), rec:num("killReward") },
		{ "space_yavin4", 20, 30, 3, 120, 2, 2500, 200 }, "recovery_duty/corellia_privateer_12: spec anchors")
	lu.assertEquals(rec:list("targetShipTypes"), { "nym_freightermedium_tier3", "nym_smuggler_freightermedium_tier4" }, "recovery_duty/corellia_privateer_12: targetShipTypes")
	lu.assertEquals(attackLists(rec), {
		{ "nym_blastboat_tier2", "nym_blastboat_tier2" },
		{ "nym_fighter_tier2", "nym_fighter_tier2", "nym_fighter_tier2" },
		{ "nym_fighter_tier2", "nym_fighter_tier2", "nym_blastboat_tier2" },
	}, "recovery_duty/corellia_privateer_12: attack lists read column-wise")
end

-- AC-6: registered, on the recovery duty base, and none of the invented destroy duty is left
function TestRecoveryDuty12:test_it_is_a_registered_recovery_duty_with_no_destroy_duty_key()
	local q = duty12()

	lu.assertNotNil(H.registered(DUTY12), DUTY12 .. ": registerScreenPlay")
	lu.assertTrue(H.registered(DUTY12).start, DUTY12 .. ": registered with start = true")
	lu.assertTrue(reaches(q, SpaceDutyRecoveryScreenplay), DUTY12 .. ": SpaceDutyRecoveryScreenplay is in its class chain")
	lu.assertFalse(reaches(q, SpaceDutyDestroyScreenplay), DUTY12 .. ": SpaceDutyDestroyScreenplay is not in its class chain")
	lu.assertEquals({ q.className, q.questName, q.questType }, { DUTY12, "corellia_privateer_12", "recovery_duty" }, DUTY12 .. ": className, questName, questType")

	for _, key in ipairs({ "totalLevels", "totalRounds", "totalWaves", "minDistance", "maxDistance", "bossShip", "shipTypes" }) do
		lu.assertNil(q[key], DUTY12 .. ": destroy duty key " .. key)
	end

	lu.assertNil(q.killReward, DUTY12 .. ": killReward (the field is creditKillBonus)")
end

-- AC-6 (Content contract C-3): the Corsec screenplay still names it as the fourth tier 2 duty
function TestRecoveryDuty12:test_the_tier_2_duty_4_constant_is_unchanged()
	lu.assertEquals(CorsecSquadronScreenplay.TIER2_QUEST_STRING_DUTY_4, { type = "recovery_duty", name = "corellia_privateer_12" }, "CorsecSquadronScreenplay.TIER2_QUEST_STRING_DUTY_4")
end

-- AC-6: Data mapping 1, the scalar fields
function TestRecoveryDuty12:test_it_maps_zone_targets_delays_conversation_escorts_pay_and_responses()
	local q = duty12()
	local rec = H.questFixture("recovery_duty", "corellia_privateer_12")
	local escort = rec:get("targetEscort")
	local label = "recovery_duty/corellia_privateer_12"

	lu.assertEquals(q.questZone, rec:get("questZone"), label .. ": questZone")
	lu.assertEquals(q.questZone, "space_yavin4", label .. ": questZone (spec)")
	lu.assertEquals(q.recoverShips, rec:list("targetShipTypes"), label .. ": recoverShips (targetShipTypes, both, in order)")
	lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), label .. ": arrivalDelay (targetArrivalDelay)")
	lu.assertEquals(q.recoveryDelay, rec:num("targetRecoverTime"), label .. ": recoveryDelay (targetRecoverTime)")
	lu.assertEquals(q.recoveryConversationMobile or "", rec:get("recoveryAppearance") or "", label .. ": recoveryConversationMobile (recoveryAppearance, empty)")
	lu.assertEquals(q.escortShips, { escort, escort }, label .. ": escortShips (targetEscort, twice)")
	lu.assertEquals(q.escortShips, { "nym_enforcer_tier2", "nym_enforcer_tier2" }, label .. ": escortShips (spec)")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), label .. ": attackDelay (attackPeriod)")
	lu.assertEquals(q.creditReward, rec:num("reward"), label .. ": creditReward (reward)")
	lu.assertEquals(q.creditReward, 2500, label .. ": creditReward (spec)")
	lu.assertEquals(q.creditKillBonus, rec:num("killReward"), label .. ": creditKillBonus (killReward)")
	lu.assertEquals(q.creditKillBonus, 200, label .. ": creditKillBonus (spec)")
	lu.assertEquals(q.numResponses, rec:num("numResponses"), label .. ": numResponses")
	lu.assertEquals(q.tauntData, { panicCount = 2, thanksCount = 2 }, label .. ": tauntData")
	lu.assertEquals({ q.sideQuest, q.sideQuestType }, { false, "" }, label .. ": sideQuest, sideQuestType")
end

-- AC-6: the five pre-recovery and three recovery points, in the fixture's order, with the patrol point coordinates
function TestRecoveryDuty12:test_it_maps_the_escort_and_recovery_paths_to_the_yavin_patrol_points()
	local q = duty12()
	local rec = H.questFixture("recovery_duty", "corellia_privateer_12")
	local label = "recovery_duty/corellia_privateer_12"

	lu.assertEquals(q.preRecoveryPoints, numbered(rec, "escortPath"), label .. ": preRecoveryPoints (escortPath)")
	lu.assertEquals(q.recoveryPoints, numbered(rec, "recoveryPath"), label .. ": recoveryPoints (recoveryPath)")

	local names = function(points)
		local out = {}

		for i, p in ipairs(points) do
			out[i] = p.patrolPointName
		end

		return out
	end

	lu.assertEquals(names(q.preRecoveryPoints), { "corellia_imperial_tier3_rebofficer_1", "corelliar_privateer_recovery_1", "corelliar_privateer_recovery_2", "corelliar_privateer_recovery_3", "corelliar_privateer_recovery_4" }, label .. ": pre-recovery point names (the SWG corelliar_ typo is kept)")
	lu.assertEquals(names(q.recoveryPoints), { "corelliar_privateer_recovery_1", "corelliar_privateer_recovery_3", "corelliar_privateer_recovery_4" }, label .. ": recovery point names")

	local coordinates = { { -3922, -1205, 474 }, { 963, -3570, -2948 }, { 2444, -7232, -2084 }, { 3418, -7360, 645 }, { 4436, -6464, 3460 } }

	for i, c in ipairs(coordinates) do
		local p = q.preRecoveryPoints[i]

		lu.assertEquals({ p.x, p.z, p.y }, c, label .. ": preRecoveryPoints[" .. i .. "] x, z, y (spec)")
	end

	local p = H.patrolPoints("space_yavin4")

	for i, point in ipairs(q.recoveryPoints) do
		local c = p[point.patrolPointName]

		lu.assertEquals({ point.x, point.z, point.y }, { c.x, c.z, c.y }, label .. ": recoveryPoints[" .. i .. "] x, z, y")
		lu.assertEquals(point.escortNumber, i, label .. ": recoveryPoints[" .. i .. "] escortNumber")
	end
end

-- AC-6: the three attack lists, column-wise (not row-wise)
function TestRecoveryDuty12:test_it_maps_the_three_attack_lists_column_wise()
	local q = duty12()
	local rec = H.questFixture("recovery_duty", "corellia_privateer_12")

	lu.assertEquals(q.attackShips, attackLists(rec), "recovery_duty/corellia_privateer_12: attackShips")
	lu.assertEquals(#q.attackShips, rec:num("numAttackShipLists"), "recovery_duty/corellia_privateer_12: number of attack lists (numAttackShipLists)")
end

-- AC-6 / I-4: every ship it spawns has a template
function TestRecoveryDuty12:test_every_ship_it_names_has_a_ship_template_file()
	local q = duty12()
	local names = {}

	for _, n in ipairs(q.recoverShips or {}) do names[#names + 1] = n end
	for _, n in ipairs(q.escortShips or {}) do names[#names + 1] = n end

	for _, list in ipairs(q.attackShips or {}) do
		for _, n in ipairs(list) do names[#names + 1] = n end
	end

	lu.assertTrue(#names >= 10, "ship names found: " .. #names)

	for _, n in ipairs(names) do
		local f = io.open(H.SCRIPTS .. "ship_mobile/ships/" .. n .. ".lua", "r")

		lu.assertNotNil(f, DUTY12 .. ": ship_mobile/ships/" .. n .. ".lua exists")

		if f then f:close() end
	end
end

---------------------------------------------------------------------------------------------
-- AC-9: the pay data of the six recovery duties
---------------------------------------------------------------------------------------------

TestRecoveryDutyPayData = {}

function TestRecoveryDutyPayData:setUp() H.reset() end

-- global -> reward, killReward, numResponses (Data mapping 2)
local PAY = {
	recovery_duty_corellia_privateer_12 = { 2500, 200, 2 },
	recovery_duty_corellia_privateer_tier4_1 = { 5000, 300, 1 },
	recovery_duty_viopa_rebel_7 = { 2500, 200, 5 },
	recovery_duty_corellia_rebel_tier4_1 = { 5000, 300, 5 },
	recovery_duty_naboo_privateer_10 = { 2500, 200, 5 },
	recovery_duty_naboo_privateer_tier4_1 = { 5000, 300, 2 },
}

for _, global in ipairs(sortedKeys(PAY)) do
	-- AC-9
	TestRecoveryDutyPayData["test_" .. global .. "_pays_the_tab_reward_and_kill_bonus_and_has_the_tab_responses"] = function()
		local q = H.expectGlobal(global, "recovery duty quest table")
		local rec = H.questFixture(q.questType, q.questName)
		local label = q.questType .. "/" .. q.questName

		lu.assertEquals({ rec:num("reward"), rec:num("killReward"), rec:num("numResponses") }, PAY[global], label .. ": the fixture matches the spec's pay table")
		lu.assertEquals(q.creditReward, rec:num("reward"), label .. ": creditReward (reward)")
		lu.assertEquals(q.creditKillBonus, rec:num("killReward"), label .. ": creditKillBonus (killReward)")
		lu.assertEquals(q.numResponses, rec:num("numResponses"), label .. ": numResponses")
		lu.assertNil(q.killReward, label .. ": no killReward key (the field is creditKillBonus)")
		lu.assertNil(rawget(q, "killReward"), label .. ": no own killReward key")
	end
end

-- AC-9 (I-2): the set of duty tables is the six of the spec
function TestRecoveryDutyPayData:test_the_six_pay_rows_cover_every_recovery_duty_table()
	lu.assertEquals(RF.dutyGlobals(), sortedKeys(PAY), "recovery duty tables vs the pay table")
end

---------------------------------------------------------------------------------------------
-- C-4: the Havoc spawn keys
---------------------------------------------------------------------------------------------

TestRecoveryHavocSpawnKeys = {}

function TestRecoveryHavocSpawnKeys:setUp() H.reset() end

-- AC-7 (C-4): Havoc tier 4 duty uses the keys the recovery base reads
function TestRecoveryHavocSpawnKeys:test_recovery_duty_corellia_rebel_tier4_1_uses_recover_ship_and_arrival_delay()
	local q = H.expectGlobal("recovery_duty_corellia_rebel_tier4_1", "recovery duty quest table")
	local rec = H.questFixture("recovery_duty", "corellia_rebel_tier4_1")

	lu.assertEquals(rec:list("targetShipTypes"), { "lambdashuttle_troop_transport_ace" }, "recovery_duty/corellia_rebel_tier4_1: targetShipTypes (spec)")
	lu.assertEquals(q.recoverShip, "lambdashuttle_troop_transport_ace", "recoverShip")
	lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), "arrivalDelay (targetArrivalDelay)")
	lu.assertEquals(q.arrivalDelay, 10, "arrivalDelay (spec)")
	lu.assertNil(rawget(q, "targetShip"), "targetShip (never read by the recovery base)")
	lu.assertNil(rawget(q, "targetArrivalDelay"), "targetArrivalDelay (never read by the recovery base)")
end

-- AC-7 (C-4): Havoc duty 7 lists both target types of the fixture
function TestRecoveryHavocSpawnKeys:test_recovery_duty_viopa_rebel_7_lists_both_target_types_of_the_fixture()
	local q = H.expectGlobal("recovery_duty_viopa_rebel_7", "recovery duty quest table")
	local rec = H.questFixture("recovery_duty", "viopa_rebel_7")

	lu.assertEquals(rec:list("targetShipTypes"), { "corsair_manowar_tier2", "corsair_behemoth_tier2" }, "recovery_duty/viopa_rebel_7: targetShipTypes (spec)")
	lu.assertEquals(q.recoverShips, rec:list("targetShipTypes"), "recoverShips (targetShipTypes)")
end

---------------------------------------------------------------------------------------------
-- I-5, I-7: strings and file hygiene
---------------------------------------------------------------------------------------------

TestRecoveryFixesFiles = {}

function TestRecoveryFixesFiles:setUp() H.reset() end

-- the touched production files
local TOUCHED = {
	"screenplays/space/SpaceRecoveryScreenplay.lua",
	"screenplays/space/SpaceDutyRecoveryScreenplay.lua",
	"screenplays/space/squadrons/CorsecSquadronScreenplay.lua",
	"screenplays/space/squadrons/HavocSquadronScreenplay.lua",
	"screenplays/space/squadrons/RsfSquadronScreenplay.lua",
	"screenplays/space/conversations/neutral/corsec_squadron/rikkhConvoHandler.lua",
	"mobile/conversations/space/neutral/corsec_squadron/rikkh_convo.lua",
}

-- I-7: LF line ends and a trailing newline
function TestRecoveryFixesFiles:test_the_touched_production_files_keep_lf_line_ends_and_a_trailing_newline()
	for _, rel in ipairs(TOUCHED) do
		local text = readFile(H.SCRIPTS .. rel)

		lu.assertNil(text:find("\r", 1, true), rel .. ": no carriage return")
		lu.assertEquals(text:sub(-1), "\n", rel .. ": trailing newline")
	end
end

-- I-7: the six fixtures this feature copied keep SWG's CRLF
function TestRecoveryFixesFiles:test_the_swg_fixture_copies_keep_crlf_line_ends()
	for _, rel in ipairs({
		"recovery_duty/corellia_privateer_12", "recovery_duty/corellia_privateer_tier4_1", "recovery_duty/viopa_rebel_7",
		"recovery/corellia_privateer_tier3_1", "recovery/viopa_rebel_3", "recovery/corellia_rebel_tier3_1",
	}) do
		local text = readFile(H.FIXTURES .. "spacequest/" .. rel .. ".tab")

		lu.assertNotNil(text:find("\r\n", 1, true), rel .. ": CRLF")
		lu.assertNil(text:find("[^\r]\n"), rel .. ": no bare LF")
	end
end

-- I-5, AC-10: every string literal of the touched sources resolves in the pre-NGE client
function TestRecoveryFixesFiles:test_the_touched_sources_use_only_string_ids_the_client_has()
	lu.assertEquals(CS.unresolved(TOUCHED), {}, "unresolved @file:id literals in the touched sources")
end

-- I-5: the reward message and the per-quest keys are in the generated fixtures
function TestRecoveryFixesFiles:test_the_client_string_fixtures_hold_the_reward_message_and_the_capture_keys()
	local quest = CS.sids("space/quest")

	lu.assertNotNil(quest, "fixture space/quest.sids")
	lu.assertTrue(quest.recovery_reward == true, "@space/quest:recovery_reward")

	for global, kind in pairs(RF.EXPECTED) do
		local q = H.expectGlobal(global, "recovery quest table")
		local ids = CS.sids("spacequest/" .. q.questType .. "/" .. q.questName)

		lu.assertNotNil(ids, global .. ": fixture spacequest/" .. q.questType .. "/" .. q.questName .. ".sids")

		for _, key in ipairs({ "capture_started", "capture_complete", "attack_stopped", "angry_disable", "panic_1", "thanks_1" }) do
			lu.assertTrue(ids[key] == true, global .. ": '" .. key .. "' in the pre-NGE client")
		end
	end
end
