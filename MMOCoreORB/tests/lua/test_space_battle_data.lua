-- Space battle quest data conformance and class contract (space-quest-stub-space-battle).
-- Spec: .claude/work/space-quest-stub-space-battle/01-spec.md (AC-1, AC-2 static part, I-2, I-3,
-- Content contract, Data mapping). The oracle is the SWG-Source .tab copies in
-- fixtures/spacequest/space_battle/, the cut-down buildout extracts in fixtures/space_zones/buildout/
-- and the patrol point files, never the Core3 tables under test.

local lu = require("luaunit")
local H = require("harness")
local B = require("battle_scenario")

B.load()

local function quest(name)
	return H.expectGlobal(B.global(name), "space battle quest table for " .. name)
end

local function label(name) return "space_battle/" .. name end

local LEGACY_KEYS = { "battleLocation", "supportShipsDelay", "enemyShipsDelay", "supportShips", "enemyShips", "alliedShips" }

local function battleGlobals()
	local out = {}

	for _, n in ipairs(H.questGlobals()) do
		if rawget(_G, n).questType == "space_battle" and rawget(_G, n).questName ~= "" then
			out[#out + 1] = n
		end
	end

	return out
end

local function contains(list, value)
	for _, v in ipairs(list or {}) do
		if v == value then
			return true
		end
	end

	return false
end

TestSpaceBattleDataConformance = {}

function TestSpaceBattleDataConformance:setUp() H.reset() end

-- AC-1
function TestSpaceBattleDataConformance:test_zone_and_the_scalar_columns_equal_the_tab()
	for _, name in ipairs(B.NAMES) do
		local o = B.oracle(name)
		local t = quest(name)

		lu.assertEquals(t.questZone, o.zone, label(name) .. ": questZone")
		lu.assertEquals(t.damageMultiplier, o.damageMultiplier, label(name) .. ": damageMultiplier")
		lu.assertEquals(t.allyArrivalDelay, o.allyDelay, label(name) .. ": allyArrivalDelay")
		lu.assertEquals(t.enemyArrivalDelay, o.enemyDelay, label(name) .. ": enemyArrivalDelay")
		lu.assertEquals(t.allyOriginDist, o.allyOrigin, label(name) .. ": allyOriginDist")
		lu.assertEquals(t.enemyOriginDist, o.enemyOrigin, label(name) .. ": enemyOriginDist")
		lu.assertEquals(t.allyArrivalDist, o.allyDist, label(name) .. ": allyArrivalDist")
		lu.assertEquals(t.enemyArrivalDist, o.enemyDist, label(name) .. ": enemyArrivalDist")
	end
end

-- AC-1
function TestSpaceBattleDataConformance:test_battle_point_has_the_patrol_point_name_coordinates_and_the_buildout_forward_axis()
	for _, name in ipairs(B.NAMES) do
		local o = B.oracle(name)
		local bp = quest(name).battlePoint

		lu.assertEquals(type(bp), "table", label(name) .. ": battlePoint must be a table, not a 'zone:name' string")
		lu.assertEquals(o.pointZone, o.zone, label(name) .. ": the .tab's battlePoint zone equals questZone")
		lu.assertEquals(bp.patrolPointName, o.pointName, label(name) .. ": battlePoint.patrolPointName")
		lu.assertEquals(bp.x, o.point.x, label(name) .. ": battlePoint.x")
		lu.assertEquals(bp.z, o.point.z, label(name) .. ": battlePoint.z")
		lu.assertEquals(bp.y, o.point.y, label(name) .. ": battlePoint.y")

		lu.assertEquals(type(bp.forward), "table", label(name) .. ": battlePoint.forward must be a table")
		lu.assertEquals(bp.forward.x, o.forward.x, label(name) .. ": battlePoint.forward.x (fltKX)")
		lu.assertEquals(bp.forward.z, o.forward.z, label(name) .. ": battlePoint.forward.z (fltKY)")
		lu.assertEquals(bp.forward.y, o.forward.y, label(name) .. ": battlePoint.forward.y (fltKZ)")
	end
end

-- AC-1
function TestSpaceBattleDataConformance:test_ally_and_enemy_forces_are_the_tab_columns_top_to_bottom()
	for _, name in ipairs(B.NAMES) do
		local o = B.oracle(name)
		local t = quest(name)

		lu.assertEquals(t.allyForce, o.allyForce, label(name) .. ": allyForce (column allyForce, top to bottom)")
		lu.assertEquals(t.enemyForce, o.enemyForce, label(name) .. ": enemyForce (column enemyForce, top to bottom)")
	end
end

-- AC-1
function TestSpaceBattleDataConformance:test_no_fixture_uses_the_conversation_columns()
	for _, name in ipairs(B.NAMES) do
		local o = B.oracle(name)

		lu.assertEquals(o.useConversation, 0, label(name) .. ": useConversation in the fixture (a later squadron that needs it must fail loudly here)")
		lu.assertEquals(o.convo, {}, label(name) .. ": convo in the fixture")
	end
end

-- AC-1, the oracle itself (guards against a fixture or extract that parsed into something unexpected)
function TestSpaceBattleDataConformance:test_the_fixtures_carry_the_values_the_spec_table_lists()
	local want = {
		corellia_privateer_tier4_3a = { "space_dantooine", "corellia_privateer_tier4_leg_3_space_battle_one", 4, 60, 90, -400, 400, -250, 250, 4, 6 },
		corellia_privateer_tier4_3c_win = { "space_dantooine", "corellia_privateer_tier4_leg_3_space_battle_two", 4, 30, 90, 500, -500, 250, -250, 4, 7 },
		corellia_privateer_tier4_3c_lose = { "space_dantooine", "corellia_privateer_tier4_leg_3_space_battle_two", 4, 30, 90, 500, -500, 250, -250, 4, 13 },
		naboo_privateer_tier3_2d = { "space_corellia", "naboo_privateer_tier3_leg_2_space_battle", 4, 68, 104, -500, 500, -250, 250, 3, 8 },
		naboo_privateer_tier3_4b = { "space_lok", "naboo_privateer_tier3_leg_4_space_battle", 4, 104, 155, 550, -550, 250, -250, 3, 5 },
		corellia_rebel_tier3_1_d = { "space_yavin4", "rebel_tier3_1_d_space_battle", 6, 20, 35, -600, 800, -100, 0, 3, 6 },
		corellia_rebel_tier3_3_b = { "space_endor", "corellia_rebel_tier3_3_b_battlepoint", 6, 60, 85, 500, -750, 50, -200, 3, 6 },
		corellia_rebel_tier3_4_c = { "space_endor", "corellia_rebel_tier3_4_c_battlepoint", 6, 60, 80, 800, -800, 100, -50, 4, 6 },
		corellia_rebel_tier4_1_a = { "space_dathomir", "corellia_rebel_tier4_1_a_battle_point", 7, 85, 60, 600, -850, 50, -100, 5, 9 },
		corellia_rebel_tier4_1_b = { "space_dathomir", "corellia_rebe_tier4_1_b_battle_point", 7, 30, 45, 600, -850, 50, -100, 6, 6 },
		corellia_rebel_tier4_3 = { "space_dathomir", "corellia_rebel_tier4_3_battle_point", 5, 60, 30, 600, -1100, 50, -200, 5, 10 },
		corellia_rebel_tier4_3_a = { "space_dathomir", "corellia_rebel_tier4_3_a_battle_point", 7, 30, 45, 600, -700, 50, -150, 3, 6 },
		corellia_rebel_tier4_4_c = { "space_endor", "corellia_rebel_tier4_4_c_battle_point", 7, 60, 85, 800, -850, 150, -200, 5, 9 },
	}

	for _, name in ipairs(B.NAMES) do
		local o = B.oracle(name)

		lu.assertEquals({ o.zone, o.pointName, o.damageMultiplier, o.allyDelay, o.enemyDelay, o.allyOrigin, o.enemyOrigin, o.allyDist, o.enemyDist, #o.allyForce, #o.enemyForce },
			want[name], label(name) .. ": {zone, point, dmg, delays, origin dists, arrival dists, ally count, enemy count} in the fixture")
	end

	local o = B.oracle("corellia_rebel_tier3_1_d")

	lu.assertEquals(o.forward, { x = 0.712721, z = -0.484232, y = -0.507492 }, "1_d forward axis in the buildout extract")
	lu.assertEquals(o.buildoutPos.x, 4546.12, "1_d buildout PX (the position is the patrol point, rounded)")
	lu.assertEquals(B.oracle("corellia_rebel_tier4_3").enemyForce[1], "imp_imperial_gunboat_tier4", "4_3 first enemy")
	lu.assertEquals(B.oracle("corellia_privateer_tier4_3c_lose").allyForce[4], "corsec_fighter_tier4", "3c_lose fourth ally")
end

-- AC-1, I-3 (the oracle's ship names; the spec says every one exists today)
function TestSpaceBattleDataConformance:test_every_fixture_ship_name_has_a_ship_template_file()
	for _, name in ipairs(B.NAMES) do
		local o = B.oracle(name)

		for _, ship in ipairs(o.allyForce) do
			lu.assertNotNil(H.shipTemplate(ship), label(name) .. ": ship template for ally " .. ship)
		end

		for _, ship in ipairs(o.enemyForce) do
			lu.assertNotNil(H.shipTemplate(ship), label(name) .. ": ship template for enemy " .. ship)
		end
	end
end

TestSpaceBattleDataInvariants = {}

function TestSpaceBattleDataInvariants:setUp() H.reset() end

-- I-2
function TestSpaceBattleDataInvariants:test_there_are_exactly_the_sixteen_battle_quests()
	local expected = {}

	for _, name in ipairs(B.NAMES) do
		expected[#expected + 1] = B.global(name)
	end

	-- RSF tier 4 (rsf-tier4) adds three battle quests; their data is tested in test_rsf_tier4_quest_data.lua.
	for _, extra in ipairs({ "4a", "4c_lose", "4c_win" }) do
		expected[#expected + 1] = B.global("naboo_privateer_tier4_" .. extra)
	end

	table.sort(expected)

	lu.assertEquals(battleGlobals(), expected, "space_battle quest globals")
end

-- I-2
function TestSpaceBattleDataInvariants:test_no_battle_quest_keeps_a_legacy_key_or_its_own_start_quest()
	for _, n in ipairs(battleGlobals()) do
		for _, key in ipairs(LEGACY_KEYS) do
			lu.assertNil(rawget(rawget(_G, n), key), n .. ": raw legacy key '" .. key .. "' must be gone")
		end

		lu.assertNil(rawget(rawget(_G, n), "startQuest"), n .. ": no raw startQuest on a quest table")
	end
end

-- I-2
function TestSpaceBattleDataInvariants:test_battle_point_is_a_table_and_the_forces_are_non_empty_lists_of_names_on_every_battle_quest()
	for _, n in ipairs(battleGlobals()) do
		local q = rawget(_G, n)

		lu.assertEquals(type(q.battlePoint), "table", n .. ": battlePoint")
		lu.assertEquals(type(q.battlePoint.patrolPointName), "string", n .. ": battlePoint.patrolPointName")
		lu.assertEquals(type(q.battlePoint.x) .. type(q.battlePoint.z) .. type(q.battlePoint.y), "numbernumbernumber", n .. ": battlePoint coordinates")

		for _, field in ipairs({ "allyForce", "enemyForce" }) do
			lu.assertEquals(type(q[field]), "table", n .. ": " .. field)
			lu.assertTrue(#q[field] > 0, n .. ": " .. field .. " is not empty")

			for i, ship in ipairs(q[field]) do
				lu.assertEquals(type(ship), "string", n .. ": " .. field .. "[" .. i .. "] is a ship template name, not a nested table")
			end
		end
	end
end

-- Scope, Data mapping: wiring and rewards are untouched
function TestSpaceBattleDataInvariants:test_parent_side_quest_wiring_and_rewards_are_unchanged()
	local a = quest("corellia_privateer_tier4_3a")
	local lose = quest("corellia_rebel_tier4_3")
	local child = quest("corellia_rebel_tier4_3_a")

	lu.assertEquals({ a.sideQuest, a.sideQuestType, a.sideQuestName, a.sideQuestSplitType, a.sideQuestDelay, a.creditReward },
		{ true, "assassinate", "corellia_privateer_tier4_3b", SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION, 1, 0 }, "3a: completion split wiring and reward")
	lu.assertEquals({ lose.sideQuest, lose.sideQuestType, lose.sideQuestName, lose.sideQuestSplitType, lose.sideFailQuestType, lose.sideFailQuestName, lose.creditReward },
		{ true, "space_battle", "corellia_rebel_tier4_3_a", SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.BIDIRECTIONAL, "survival", "corellia_rebel_tier4_3_b", 10000 },
		"4_3: bidirectional split wiring and reward")
	lu.assertEquals({ child.parentQuest, child.parentQuestType, child.parentQuestName }, { "space_battle_corellia_rebel_tier4_3", "space_battle", "corellia_rebel_tier4_3" },
		"4_3_a: parent wiring")
end

-- Content contract: registration
function TestSpaceBattleDataInvariants:test_every_battle_quest_and_the_class_stay_registered()
	for _, name in ipairs(B.NAMES) do
		lu.assertEquals(H.registered(B.global(name)) and H.registered(B.global(name)).start, true, B.global(name) .. ": registerScreenPlay(name, true)")
	end

	lu.assertNotNil(H.registered("SpaceBattleScreenplay"), "SpaceBattleScreenplay registered")
	lu.assertEquals(H.registered("SpaceBattleScreenplay").start, false, "SpaceBattleScreenplay is registered with start = false")
end

-- I-3 (forces fight)
function TestSpaceBattleDataInvariants:test_every_ally_and_enemy_is_hostile_to_the_other_force()
	for _, name in ipairs(B.NAMES) do
		local t = quest(name)

		lu.assertEquals(type(t.allyForce), "table", label(name) .. ": allyForce")
		lu.assertEquals(type(t.enemyForce), "table", label(name) .. ": enemyForce")
		lu.assertTrue(#t.allyForce > 0 and #t.enemyForce > 0, label(name) .. ": both forces are non-empty")

		for _, allyName in ipairs(t.allyForce) do
			local a = H.shipTemplate(allyName)

			lu.assertNotNil(a, label(name) .. ": ship template for ally " .. tostring(allyName))

			for _, enemyName in ipairs(t.enemyForce) do
				local e = H.shipTemplate(enemyName)

				lu.assertNotNil(e, label(name) .. ": ship template for enemy " .. tostring(enemyName))
				lu.assertTrue(contains(e.enemyFactions, a.spaceFaction), label(name) .. ": enemy " .. enemyName .. " is hostile to the faction of ally " .. allyName .. " (" .. tostring(a.spaceFaction) .. ")")

				if a.enemyFactions ~= nil then
					lu.assertTrue(contains(a.enemyFactions, e.spaceFaction), label(name) .. ": ally " .. allyName .. " is hostile to the faction of enemy " .. enemyName .. " (" .. tostring(e.spaceFaction) .. ")")
				end
			end
		end
	end
end

TestSpaceBattleClassContract = {}

function TestSpaceBattleClassContract:setUp() H.reset() end

local function class()
	return H.expectGlobal("SpaceBattleScreenplay", "screenplays/space/SpaceBattleScreenplay.lua")
end

-- AC-2, Content contract: class identity and enums
function TestSpaceBattleClassContract:test_the_class_names_itself_and_defines_the_enums()
	local c = class()

	lu.assertEquals(c.className, "SpaceBattleScreenplay", "className")
	lu.assertEquals(c.questType, "space_battle", "questType")
	lu.assertEquals(c.SIDES, { ALLY = 1, ENEMY = 2 }, "SIDES")
	lu.assertEquals(c.STAGES, { SETUP = 1, BATTLE = 2, RESOLVED = 3 }, "STAGES")
end

-- AC-2, Content contract: constants, each with its source
function TestSpaceBattleClassContract:test_the_tuning_constants_are_readable_on_the_class()
	local c = class()
	local want = { setupCheckDelay = 1, resolveDelay = 2, warpoutTimeout = 1500, formationSpread = 100 }

	for key, value in pairs(want) do
		lu.assertEquals(c[key], value, "SpaceBattleScreenplay." .. key)
	end
end

-- Content contract: per-quest data defaults on the class
function TestSpaceBattleClassContract:test_the_data_fields_have_empty_defaults_on_the_class()
	local c = class()

	lu.assertEquals(c.battlePoint, {}, "battlePoint default")
	lu.assertEquals(c.damageMultiplier, 1, "damageMultiplier default")
	lu.assertEquals(c.allyArrivalDelay, 0, "allyArrivalDelay default")
	lu.assertEquals(c.enemyArrivalDelay, 0, "enemyArrivalDelay default")
	lu.assertEquals(c.allyOriginDist, 0, "allyOriginDist default")
	lu.assertEquals(c.enemyOriginDist, 0, "enemyOriginDist default")
	lu.assertEquals(c.allyArrivalDist, 0, "allyArrivalDist default")
	lu.assertEquals(c.enemyArrivalDist, 0, "enemyArrivalDist default")
	lu.assertEquals(c.allyForce, {}, "allyForce default")
	lu.assertEquals(c.enemyForce, {}, "enemyForce default")
end

-- Content contract: public methods tests call
function TestSpaceBattleClassContract:test_the_public_methods_exist()
	local c = class()

	for _, m in ipairs({ "start", "startQuest", "completeQuest", "failQuest", "resetQuest", "enteredZone", "notifyBattleShipDestroyed", "cleanUpQuestData" }) do
		lu.assertEquals(type(c[m]), "function", "expected the rewritten SpaceBattleScreenplay to define " .. m)
	end
end

-- Content contract (D-14): the class does not mix in SpaceAttackWaves
function TestSpaceBattleClassContract:test_the_class_does_not_mix_in_space_attack_waves()
	local c = class()
	local waves = H.expectGlobal("SpaceAttackWaves", "screenplays/space/SpaceAttackWaves.lua")

	for name, value in pairs(waves) do
		if type(value) == "function" and name ~= "mixInto" then
			lu.assertNil(rawget(c, name), "SpaceBattleScreenplay must not carry the SpaceAttackWaves function " .. name)
		end
	end
end
