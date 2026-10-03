-- RSF tier 3 renames (F2): delivery_no_pickup 3b, surprise attacks 4c/4d/4e, the deleted legacy tables, the
-- identity counts and the tier 3 constants, conformance against SWG-Source.
-- Spec: .claude/work/rsf-tier3-renames/01-spec.md (AC-1, AC-2, AC-3, invariants I-1 .. I-6, Content contract 1, 2,
-- Data mapping).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/, never the Core3 tables under test. The
-- values of the spec tables are repeated as literal anchors so a misparsed fixture cannot make a wrong table look right.
-- The generic checks over D.QUESTS (delivery_scenario.lua) and the 18 Dulios-reachable tables
-- (test_rsf_tier3_quest_data.lua) also cover the new tables; this file adds what is specific to F2.

local lu = require("luaunit")
local H = require("harness")
local D = require("delivery_scenario")
local R = require("surprise_replay")

H.loadSquadron("CorsecSquadronScreenplay")
H.loadSquadron("HavocSquadronScreenplay")
H.loadSquadron("RsfSquadronScreenplay")

local SPLIT = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES

local function g(questType, suffix) return questType .. "_naboo_privateer_tier3_" .. suffix end

local DNP3B = g("delivery_no_pickup", "3b")
local SA4C, SA4D, SA4E = g("destroy_surpriseattack", "4c"), g("destroy_surpriseattack", "4d"), g("destroy_surpriseattack", "4e")
local NEW_GLOBALS = { DNP3B, SA4C, SA4D, SA4E }
local DELETED = { g("delivery", "3b"), g("survival", "4c"), g("destroy_surpriseattack", "4_initial") }

local function quest(global) return H.expectGlobal(global, "RSF tier 3 quest table (rsf-tier3-renames)") end

local function fixtureOf(global)
	local q = quest(global)

	return H.questFixture(q.questType, q.questName)
end

local function countOfType(...)
	local wanted, n = {}, 0

	for _, t in ipairs({ ... }) do
		wanted[t] = true
	end

	for _, name in ipairs(H.questGlobals()) do
		if wanted[rawget(_G, name).questType] then
			n = n + 1
		end
	end

	return n
end

---------------------------------------------------------------------------------------------
-- AC-1: delivery_no_pickup 3b
---------------------------------------------------------------------------------------------

TestRsfRenamesDeliveryNoPickup3b = {}

function TestRsfRenamesDeliveryNoPickup3b:setUp() H.reset() end

-- AC-1
function TestRsfRenamesDeliveryNoPickup3b:test_the_fixture_carries_the_values_the_spec_lists()
	local o = D.oracle("delivery_no_pickup", "naboo_privateer_tier3_3b")
	local rec = H.questFixture("delivery_no_pickup", "naboo_privateer_tier3_3b")

	lu.assertEquals(o.hasPickup, false, "fixture: no pickupPoint")
	lu.assertEquals({ o.zone, o.deliveryShip, o.listCount, o.period, o.listType }, { "space_lok", "rsf_rawl_tier3", 2, 50, 0 }, "fixture anchors: zone, ship, lists, period, list type")
	lu.assertEquals(o.lists, { { "blacksun_aggressor_tier3", "blacksun_aggressor_tier3" }, { "blacksun_fighter_s01_tier3", "blacksun_fighter_s01_tier3" } }, "fixture anchors: attack lists (column N = list N)")
	lu.assertEquals({ rec:get("triggerEvent"), rec:get("triggerSplitCondition"), rec:get("triggerArg"), rec:num("triggerDelay") }, { "splitquest", "success", "survival:naboo_privateer_tier3_3c", 0 }, "fixture anchors: split")
	lu.assertEquals(rec:get("deliveryPoint"), "space_lok:hostage_recovery_3", "fixture anchor: deliveryPoint")
end

-- AC-1
function TestRsfRenamesDeliveryNoPickup3b:test_it_is_a_delivery_no_pickup_quest_without_a_pickup_leg()
	local q = quest(DNP3B)

	lu.assertEquals(q.className, DNP3B, "className")
	lu.assertEquals({ q.questType, q.questName }, { "delivery_no_pickup", "naboo_privateer_tier3_3b" }, "questType, questName")
	lu.assertEquals(q.hasPickup, false, "hasPickup")
	lu.assertEquals(q.pickupPoint, {}, "pickupPoint (inherited, unset)")
	lu.assertEquals(q.pickupShip, "", "pickupShip (inherited, unset)")
end

-- AC-1
function TestRsfRenamesDeliveryNoPickup3b:test_delivery_data_equals_the_fixture_and_the_content_contract()
	local q = quest(DNP3B)
	local o = D.oracle("delivery_no_pickup", "naboo_privateer_tier3_3b")
	local p = H.patrolPoints("space_lok").hostage_recovery_3

	lu.assertNotNil(p, "patrol point hostage_recovery_3 in space_lok")
	lu.assertEquals(q.questZone, o.zone, DNP3B .. ": questZone")
	lu.assertEquals(q.deliveryShip, o.deliveryShip, DNP3B .. ": deliveryShip")
	lu.assertEquals(q.deliveryPoint, { patrolPointName = o.delivery.name, x = o.delivery.x, z = o.delivery.z, y = o.delivery.y }, DNP3B .. ": deliveryPoint (fixture)")
	lu.assertEquals(q.deliveryPoint, { patrolPointName = "hostage_recovery_3", x = p.x, z = p.z, y = p.y }, DNP3B .. ": deliveryPoint (patrol point file)")
	lu.assertEquals({ q.deliveryPoint.x, q.deliveryPoint.z, q.deliveryPoint.y }, { -6832, 2296, -3612 }, DNP3B .. ": deliveryPoint coordinates (spec)")
	lu.assertEquals(q.attackShipLists, o.lists, DNP3B .. ": attackShipLists (column N of the .tab is list N)")
	lu.assertEquals(#q.attackShipLists, o.listCount, DNP3B .. ": number of lists")
	lu.assertEquals(q.attackPeriod, o.period, DNP3B .. ": attackPeriod")
	lu.assertEquals(q.attackPeriod, 50, DNP3B .. ": attackPeriod (spec)")
	lu.assertEquals(q.attackListType, o.listType, DNP3B .. ": attackListType (sequential = 0)")
	lu.assertEquals(q.creditReward, 0, DNP3B .. ": creditReward")
	lu.assertEquals(q.itemReward, {}, DNP3B .. ": itemReward")
end

-- AC-1: split to the survival 3c, delay 0 + 5 (the rule of F1: triggerDelay + 5 on a success split)
function TestRsfRenamesDeliveryNoPickup3b:test_it_splits_to_survival_3c_on_completion_after_5()
	local q = quest(DNP3B)
	local rec = fixtureOf(DNP3B)
	local sideType, sideName = H.Tab.splitQuestRef(rec:get("triggerArg"))

	lu.assertTrue(q.sideQuest, DNP3B .. ": sideQuest")
	lu.assertEquals({ q.sideQuestType, q.sideQuestName }, { sideType, sideName }, DNP3B .. ": side quest (triggerArg)")
	lu.assertEquals({ q.sideQuestType, q.sideQuestName }, { "survival", "naboo_privateer_tier3_3c" }, DNP3B .. ": side quest (spec)")
	lu.assertEquals(q.sideQuestSplitType, SPLIT.COMPLETION, DNP3B .. ": sideQuestSplitType")
	lu.assertEquals(q.sideQuestDelay, (rec:num("triggerDelay") or 0) + 5, DNP3B .. ": sideQuestDelay (triggerDelay + 5)")
	lu.assertEquals(q.sideQuestDelay, 5, DNP3B .. ": sideQuestDelay (spec)")
end

-- AC-1: the parent fields name 3a, and 3a / 3c point at the new global (the 3a fixture's triggerArg).
function TestRsfRenamesDeliveryNoPickup3b:test_3a_splits_to_it_and_names_it_in_3c_as_parent()
	local q, a, c = quest(DNP3B), quest(g("inspect", "3a")), quest(g("survival", "3c"))
	local sideType, sideName = H.Tab.splitQuestRef(fixtureOf(g("inspect", "3a")):get("triggerArg"))

	lu.assertEquals({ sideType, sideName }, { "delivery_no_pickup", "naboo_privateer_tier3_3b" }, "3a fixture triggerArg")
	lu.assertEquals({ a.sideQuestType, a.sideQuestName }, { sideType, sideName }, "inspect 3a: side quest (triggerArg)")
	lu.assertEquals({ q.parentQuest, q.parentQuestType, q.parentQuestName }, { g("inspect", "3a"), "inspect", "naboo_privateer_tier3_3a" }, DNP3B .. ": parent fields")
	lu.assertEquals({ c.parentQuest, c.parentQuestType, c.parentQuestName }, { DNP3B, "delivery_no_pickup", "naboo_privateer_tier3_3b" }, "survival 3c: parent fields")
	lu.assertEquals({ a.sideQuestSplitType, a.sideQuestDelay }, { SPLIT.COMPLETION, 10 }, "inspect 3a: split type, delay (5 + 5, unchanged)")
end

-- AC-1: 3b is part of the generic delivery conformance run
function TestRsfRenamesDeliveryNoPickup3b:test_the_generic_delivery_conformance_list_names_the_new_type()
	local found = false

	for _, row in ipairs(D.QUESTS) do
		lu.assertFalse(row[1] == "delivery" and row[2] == "naboo_privateer_tier3_3b", "D.QUESTS must not list the deleted delivery 3b")
		found = found or (row[1] == "delivery_no_pickup" and row[2] == "naboo_privateer_tier3_3b")
	end

	lu.assertTrue(found, "D.QUESTS lists delivery_no_pickup naboo_privateer_tier3_3b")
end

---------------------------------------------------------------------------------------------
-- AC-2: surprise attacks 4c, 4d, 4e
---------------------------------------------------------------------------------------------

TestRsfRenamesSurpriseAttacks = {}

function TestRsfRenamesSurpriseAttacks:setUp() H.reset() end

-- The Content contract table: global, name, parent global/type/name, side type/name, spawns
local SURPRISE = {
	{ SA4C, "naboo_privateer_tier3_4c", g("space_battle", "4b"), "space_battle", "naboo_privateer_tier3_4b", "destroy_surpriseattack", "naboo_privateer_tier3_4d", { { count = 3, shipName = "blacksun_marauder_tier3" } } },
	{ SA4D, "naboo_privateer_tier3_4d", SA4C, "destroy_surpriseattack", "naboo_privateer_tier3_4c", "destroy_surpriseattack", "naboo_privateer_tier3_4e", { { count = 4, shipName = "blacksun_vehement_tier3" } } },
	{ SA4E, "naboo_privateer_tier3_4e", SA4D, "destroy_surpriseattack", "naboo_privateer_tier3_4d", "assassinate", "naboo_privateer_tier3_4f", { { count = 1, shipName = "blacksun_gunship_tier2" } } },
}

-- AC-2
function TestRsfRenamesSurpriseAttacks:test_the_replay_of_the_swg_spawn_loop_gives_3_marauders_4_vehements_and_1_gunship()
	lu.assertEquals(R.runs(R.replay("naboo_privateer_tier3_4c")), { { count = 3, shipName = "blacksun_marauder_tier3" } }, "4c replay")
	lu.assertEquals(R.runs(R.replay("naboo_privateer_tier3_4d")), { { count = 4, shipName = "blacksun_vehement_tier3" } }, "4d replay")
	lu.assertEquals(R.runs(R.replay("naboo_privateer_tier3_4e")), { { count = 1, shipName = "blacksun_gunship_tier2" } }, "4e replay")
end

-- AC-2
function TestRsfRenamesSurpriseAttacks:test_zone_and_spawns_equal_the_fixture_replay()
	for _, row in ipairs(SURPRISE) do
		local q, rec = quest(row[1]), fixtureOf(row[1])

		lu.assertEquals(q.questZone, rec:get("questZone"), row[1] .. ": questZone")
		lu.assertEquals(q.surpriseAttackShips.zone, rec:get("questZone"), row[1] .. ": surpriseAttackShips.zone")
		lu.assertEquals(q.surpriseAttackShips.spawns, R.runs(R.replay(row[2])), row[1] .. ": surpriseAttackShips.spawns (SWG spawn loop replay)")
		lu.assertEquals(q.surpriseAttackShips, { zone = "space_lok", spawns = row[8] }, row[1] .. ": surpriseAttackShips (spec)")
	end
end

-- AC-2
function TestRsfRenamesSurpriseAttacks:test_identity_rewards_and_parent_fields_equal_the_content_contract()
	for _, row in ipairs(SURPRISE) do
		local q = quest(row[1])

		lu.assertEquals(q.className, row[1], row[1] .. ": className")
		lu.assertEquals({ q.questType, q.questName }, { "destroy_surpriseattack", row[2] }, row[1] .. ": questType, questName")
		lu.assertEquals(q.creditReward, 0, row[1] .. ": creditReward")
		lu.assertEquals(q.itemReward, {}, row[1] .. ": itemReward")
		lu.assertEquals({ q.parentQuest, q.parentQuestType, q.parentQuestName }, { row[3], row[4], row[5] }, row[1] .. ": parent fields")
	end
end

-- AC-2: the split fields derive from the fixture's triggerArg, success split, delay 0 + 5
function TestRsfRenamesSurpriseAttacks:test_split_fields_equal_the_fixture()
	for _, row in ipairs(SURPRISE) do
		local q, rec = quest(row[1]), fixtureOf(row[1])
		local sideType, sideName = H.Tab.splitQuestRef(rec:get("triggerArg"))

		lu.assertEquals(rec:get("triggerEvent"), "splitquest", row[1] .. ": fixture triggerEvent")
		lu.assertEquals(rec:get("triggerSplitCondition"), "success", row[1] .. ": fixture split condition")
		lu.assertTrue(q.sideQuest, row[1] .. ": sideQuest")
		lu.assertEquals({ q.sideQuestType, q.sideQuestName }, { sideType, sideName }, row[1] .. ": side quest (triggerArg)")
		lu.assertEquals({ q.sideQuestType, q.sideQuestName }, { row[6], row[7] }, row[1] .. ": side quest (spec)")
		lu.assertEquals(q.sideQuestSplitType, SPLIT.COMPLETION, row[1] .. ": sideQuestSplitType")
		lu.assertEquals(q.sideQuestDelay, (rec:num("triggerDelay") or 0) + 5, row[1] .. ": sideQuestDelay (triggerDelay + 5)")
		lu.assertEquals(q.sideQuestDelay, 5, row[1] .. ": sideQuestDelay (spec)")
	end
end

-- AC-2: 4b and 4f are re-wired to the new tables (F1 exceptions E-2 end)
function TestRsfRenamesSurpriseAttacks:test_4b_splits_to_4c_and_4f_has_4e_as_parent()
	local b, f = quest(g("space_battle", "4b")), quest(g("assassinate", "4f"))
	local sideType, sideName = H.Tab.splitQuestRef(fixtureOf(g("space_battle", "4b")):get("triggerArg"))

	lu.assertEquals({ sideType, sideName }, { "destroy_surpriseattack", "naboo_privateer_tier3_4c" }, "4b fixture triggerArg")
	lu.assertEquals({ b.sideQuestType, b.sideQuestName }, { sideType, sideName }, "space_battle 4b: side quest (triggerArg)")
	lu.assertEquals(b.sideQuestDelay, 5, "space_battle 4b: sideQuestDelay (unchanged)")
	lu.assertEquals({ f.parentQuest, f.parentQuestType, f.parentQuestName }, { SA4E, "destroy_surpriseattack", "naboo_privateer_tier3_4e" }, "assassinate 4f: parent fields")
	lu.assertFalse(f.sideQuest and true or false, "assassinate 4f: sideQuest")
end

---------------------------------------------------------------------------------------------
-- AC-3: identity, registration, counts, chains, constants
---------------------------------------------------------------------------------------------

TestRsfRenamesIdentity = {}

function TestRsfRenamesIdentity:setUp() H.reset() end

-- AC-3
function TestRsfRenamesIdentity:test_the_three_replaced_tables_are_nil_and_not_registered()
	for _, name in ipairs(DELETED) do
		lu.assertNil(rawget(_G, name), name .. ": global must be gone")
		lu.assertNil(H.registered(name), name .. ": registerScreenPlay must be gone")
	end
end

-- AC-3, I-1
function TestRsfRenamesIdentity:test_the_four_new_tables_are_registered_as_started_screenplays_under_their_own_names()
	for _, name in ipairs(NEW_GLOBALS) do
		local q = quest(name)

		lu.assertEquals(q.className, name, name .. ": className")
		lu.assertEquals(q.questType .. "_" .. q.questName, name, name .. ": questType_questName")
		lu.assertNotNil(H.registered(name), name .. ": registerScreenPlay was called")
		lu.assertTrue(H.registered(name).start, name .. ": registered with start = true")
	end
end

-- AC-3, I-1
function TestRsfRenamesIdentity:test_the_quest_global_counts_are_165_19_8_and_8()
	lu.assertEquals(#H.questGlobals(), 165, "space quest globals")
	lu.assertEquals(countOfType("destroy_surpriseattack"), 19, "surprise attack globals")
	-- The spec says 7, which is the count of survival quests with a SWG-Source survival .tab (survival_scenario's S.NAMES). The
	-- 9 survival globals before F2 (8 of them from S.NAMES' list plus the 4c placeholder, and RSF tier 4's survival 3c) become 8.
	lu.assertEquals(countOfType("survival"), 8, "survival globals (7 from the S.NAMES list plus survival_naboo_privateer_tier4_3c)")
	lu.assertEquals(countOfType("delivery", "delivery_no_pickup"), 8, "delivery plus delivery_no_pickup globals")
end

-- AC-3, I-2
function TestRsfRenamesIdentity:test_the_four_new_tables_pay_nothing()
	for _, name in ipairs(NEW_GLOBALS) do
		local q = quest(name)

		lu.assertEquals(q.creditReward, 0, name .. ": creditReward")
		lu.assertEquals(q.itemReward, {}, name .. ": itemReward")
	end
end

-- AC-3, I-3, I-5: the wiring from every chain head, derived from the chain walk
function TestRsfRenamesIdentity:test_the_mission_3_and_4_chains_walk_the_new_tables_in_order()
	local function names(head)
		local out = {}

		for i, member in ipairs(SpaceHelpers:getSpaceQuestChain(head)) do
			out[i] = member.global
		end

		return out
	end

	lu.assertEquals(names(g("inspect", "3a")), { g("inspect", "3a"), DNP3B, g("survival", "3c"), g("destroy_surpriseattack", "3e") }, "mission 3 chain")
	lu.assertEquals(names(g("assassinate", "4a")), { g("assassinate", "4a"), g("space_battle", "4b"), SA4C, SA4D, SA4E, g("assassinate", "4f") }, "mission 4 chain")
	lu.assertEquals(#names(g("recovery", "1a")), 4, "mission 1 chain length")
	lu.assertEquals(#names(g("escort", "2a")), 4, "mission 2 chain length")
end

-- AC-3, I-3: no carve-out any more: every Dulios-reachable table with a split has an existing target that names it back
function TestRsfRenamesIdentity:test_every_split_of_the_18_chain_members_has_a_target_that_names_it_as_parent()
	local members = {}

	for _, head in ipairs({ g("recovery", "1a"), g("escort", "2a"), g("inspect", "3a"), g("assassinate", "4a") }) do
		for _, m in ipairs(SpaceHelpers:getSpaceQuestChain(head)) do
			members[#members + 1] = m.global
		end
	end

	lu.assertEquals(#members, 18, "chain members of the four missions")

	for _, name in ipairs(members) do
		local q = quest(name)

		if q.sideQuest then
			local target = rawget(_G, q.sideQuestType .. "_" .. q.sideQuestName)

			lu.assertNotNil(target, name .. ": split target " .. q.sideQuestType .. "_" .. q.sideQuestName)
			lu.assertEquals({ target.questType, target.questName }, { q.sideQuestType, q.sideQuestName }, name .. ": target type, name")
			lu.assertEquals(target.parentQuest, name, name .. ": the target names it back as parentQuest")
			lu.assertEquals(target.parentQuestType, q.questType, name .. ": the target's parentQuestType")
			lu.assertEquals(target.parentQuestName, q.questName, name .. ": the target's parentQuestName")
		end
	end
end

-- AC-3 (Content contract 2): the tier 3 constants
function TestRsfRenamesIdentity:test_the_tier_3_constants_equal_the_content_contract()
	local R3 = RsfSquadronScreenplay
	local function c(t, n) return { type = t, name = "naboo_privateer_tier3_" .. n } end

	lu.assertEquals(R3.TIER3_QUEST_STRING_3, c("inspect", "3a"), "TIER3_QUEST_STRING_3")
	lu.assertEquals(R3.TIER3_QUEST_STRING_3_SIDE1, c("delivery_no_pickup", "3b"), "TIER3_QUEST_STRING_3_SIDE1")
	lu.assertEquals(R3.TIER3_QUEST_STRING_3_SIDE2, c("survival", "3c"), "TIER3_QUEST_STRING_3_SIDE2")
	lu.assertEquals(R3.TIER3_QUEST_STRING_3_SIDE3, c("destroy_surpriseattack", "3e"), "TIER3_QUEST_STRING_3_SIDE3")
	lu.assertEquals(R3.TIER3_QUEST_STRING_4, c("assassinate", "4a"), "TIER3_QUEST_STRING_4")
	lu.assertEquals(R3.TIER3_QUEST_STRING_4_SIDE1, c("space_battle", "4b"), "TIER3_QUEST_STRING_4_SIDE1")
	lu.assertEquals(R3.TIER3_QUEST_STRING_4_SIDE2, c("destroy_surpriseattack", "4c"), "TIER3_QUEST_STRING_4_SIDE2")
	lu.assertEquals(R3.TIER3_QUEST_STRING_4_SIDE3, c("destroy_surpriseattack", "4d"), "TIER3_QUEST_STRING_4_SIDE3")
	lu.assertEquals(R3.TIER3_QUEST_STRING_4_SIDE4, c("destroy_surpriseattack", "4e"), "TIER3_QUEST_STRING_4_SIDE4")
	lu.assertEquals(R3.TIER3_QUEST_STRING_4_SIDE5, c("assassinate", "4f"), "TIER3_QUEST_STRING_4_SIDE5")

	-- missions 1 and 2 stay as they are
	lu.assertEquals(R3.TIER3_QUEST_STRING_1, c("recovery", "1a"), "TIER3_QUEST_STRING_1")
	lu.assertEquals(R3.TIER3_QUEST_STRING_2, c("escort", "2a"), "TIER3_QUEST_STRING_2")
end

-- AC-3 (Content contract 2): the legacy data the migration and the surrender read
function TestRsfRenamesIdentity:test_the_legacy_tier_3_data_equals_the_content_contract()
	local R3 = RsfSquadronScreenplay

	lu.assertEquals(R3.LEGACY_TIER3_QUESTS, {
		{ type = "delivery", name = "naboo_privateer_tier3_3b", moveTo = { { type = "delivery_no_pickup", name = "naboo_privateer_tier3_3b" } } },
		{ type = "survival", name = "naboo_privateer_tier3_4c", moveTo = {
			{ type = "destroy_surpriseattack", name = "naboo_privateer_tier3_4c" },
			{ type = "destroy_surpriseattack", name = "naboo_privateer_tier3_4d" },
			{ type = "destroy_surpriseattack", name = "naboo_privateer_tier3_4e" },
		} },
		{ type = "destroy_surpriseattack", name = "naboo_privateer_tier3_4_initial", moveTo = {} },
	}, "LEGACY_TIER3_QUESTS")
	lu.assertEquals(R3.LEGACY_TIER3_STATUS, {
		{ old = "naboo_privateer_tier3_4_initial:attempted", new = "naboo_privateer_tier3_4a:attempted" },
		{ old = "naboo_privateer_tier3_4_initial:reward", new = "naboo_privateer_tier3_4a:reward" },
	}, "LEGACY_TIER3_STATUS")
	lu.assertEquals(R3.LEGACY_MIGRATION_STEPS, { "migrateLegacyTier3", "migrateLegacyTier2", "migrateLegacyTier2Duties" }, "LEGACY_MIGRATION_STEPS")
	lu.assertEquals(type(R3.migrateLegacyTier3), "function", "RsfSquadronScreenplay:migrateLegacyTier3")
	lu.assertEquals(type(R3.migrateLegacyProgress), "function", "RsfSquadronScreenplay:migrateLegacyProgress")
end

-- AC-3: the invented patrol points of the deleted delivery stay (F3 deletes them), as the spec's Scope Out says
function TestRsfRenamesIdentity:test_the_real_swg_buildout_points_of_the_deleted_delivery_stay_in_space_lok()
	lu.assertNotNil(H.patrolPoints("space_lok").naboo_privateer_tier3_leg_3_deliver_pickup, "naboo_privateer_tier3_leg_3_deliver_pickup")
	lu.assertNotNil(H.patrolPoints("space_lok").naboo_privateer_tier3_leg_3_deliver_delivery, "naboo_privateer_tier3_leg_3_deliver_delivery")
end

---------------------------------------------------------------------------------------------
-- I-6: no legacy name in live code
---------------------------------------------------------------------------------------------

TestRsfRenamesNoLegacyNames = {}

local LEGACY_PATTERNS = { "delivery_naboo_privateer_tier3_3b", "survival_naboo_privateer_tier3_4c", "naboo_privateer_tier3_4_initial" }

local function readLines(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local out = {}

	for line in f:lines() do
		out[#out + 1] = line
	end

	f:close()
	return out
end

local function stripComment(line)
	return (line:gsub("%-%-.*$", ""))
end

-- I-6
function TestRsfRenamesNoLegacyNames:test_no_script_names_a_legacy_quest_outside_the_rsf_legacy_data()
	local rsfPath = H.SCRIPTS .. "screenplays/space/squadrons/RsfSquadronScreenplay.lua"
	local offenders = {}

	local pipe = assert(io.popen("grep -rIlE '" .. table.concat(LEGACY_PATTERNS, "|") .. "' " .. H.SCRIPTS .. " --include='*.lua' 2>/dev/null"))

	for file in pipe:lines() do
		if file ~= rsfPath then
			offenders[#offenders + 1] = file
		end
	end

	pipe:close()
	table.sort(offenders)
	lu.assertEquals(offenders, {}, "scripts other than RsfSquadronScreenplay.lua that name a legacy quest")

	-- inside RSF only the LEGACY_TIER3_QUESTS .. LEGACY_MIGRATION_STEPS block (comments excluded) may name them
	local inBlock, bad = false, {}

	for n, line in ipairs(readLines(rsfPath)) do
		local code = stripComment(line:gsub("\r$", ""))

		if code:find("LEGACY_TIER3_QUESTS", 1, true) and code:find("=", 1, true) then
			inBlock = true
		end

		if not inBlock then
			for _, pattern in ipairs(LEGACY_PATTERNS) do
				if code:find(pattern, 1, true) then
					bad[#bad + 1] = n .. ": " .. code
				end
			end
		end

		if inBlock and code:find("LEGACY_MIGRATION_STEPS", 1, true) and code:find("=", 1, true) then
			inBlock = false
		end
	end

	lu.assertEquals(bad, {}, "RsfSquadronScreenplay.lua code lines outside the LEGACY_* data that name a legacy quest")
end
