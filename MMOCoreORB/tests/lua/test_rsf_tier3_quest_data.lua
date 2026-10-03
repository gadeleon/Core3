-- RSF Squadron tier 3 (Commander Dulios): rewards, split wiring, the mission 3 ambush (3e) and the
-- mission 4 assassinations (4a, 4f), conformance against SWG-Source.
-- Spec: .claude/work/rsf-tier3-data/01-spec.md (AC-1 data part, AC-2, AC-3, AC-4, AC-9 chain lists,
-- invariants I-1 .. I-5, Content contract 1, Data mapping).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/ and the J (Dulios) script copy in
-- fixtures/script/conversation/, never the Core3 tables under test. The values spelled out in the spec tables
-- are repeated as anchors so a misparsed fixture cannot make a wrong table look right.
--
-- rsf-tier3-renames (F2) ended the conformance exceptions E-1 and E-2: 3a splits to delivery_no_pickup 3b, 3c's
-- parent is that global, 4b splits to destroy_surpriseattack 4c and 4f's parent is destroy_surpriseattack 4e, all
-- equal to the fixtures. The payload of the four new tables is tested in test_rsf_tier3_renames_data.lua.

local lu = require("luaunit")
local H = require("harness")

H.loadSquadron("CorsecSquadronScreenplay")
H.loadSquadron("HavocSquadronScreenplay")
H.loadSquadron("RsfSquadronScreenplay")

local SPLIT = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES

local function g(questType, suffix) return questType .. "_naboo_privateer_tier3_" .. suffix end

-- The 14 rows of spec table W: { global, sideQuest, split, side global, delay, patrolStart, parent global }.
-- split nil = NONE or not set; patrolStart nil = not set by the table (class default 0).
local W = {
	{ g("recovery", "1a"), true, SPLIT.COMPLETION, g("patrol", "1b"), 5, nil, "" },
	{ g("patrol", "1b"), true, SPLIT.PATROL_POINT, g("destroy_surpriseattack", "1c"), 44, 1, g("recovery", "1a") },
	{ g("destroy_surpriseattack", "1c"), true, SPLIT.COMPLETION, g("assassinate", "1d"), 5, nil, g("patrol", "1b") },
	{ g("assassinate", "1d"), false, nil, nil, nil, nil, g("destroy_surpriseattack", "1c") },
	{ g("escort", "2a"), true, SPLIT.COMPLETION, g("destroy_surpriseattack", "2c"), 5, nil, "" },
	{ g("destroy_surpriseattack", "2c"), true, SPLIT.COMPLETION, g("space_battle", "2d"), 5, nil, g("escort", "2a") },
	{ g("space_battle", "2d"), true, SPLIT.COMPLETION, g("rescue", "2e"), 5, nil, g("destroy_surpriseattack", "2c") },
	{ g("rescue", "2e"), false, nil, nil, nil, nil, g("space_battle", "2d") },
	{ g("inspect", "3a"), true, SPLIT.COMPLETION, g("delivery_no_pickup", "3b"), 10, nil, "" },
	{ g("survival", "3c"), true, SPLIT.COMPLETION, g("destroy_surpriseattack", "3e"), 5, nil, g("delivery_no_pickup", "3b") },
	{ g("destroy_surpriseattack", "3e"), false, nil, nil, nil, nil, g("survival", "3c") },
	{ g("assassinate", "4a"), true, SPLIT.COMPLETION, g("space_battle", "4b"), 5, nil, "" },
	{ g("space_battle", "4b"), true, SPLIT.COMPLETION, g("destroy_surpriseattack", "4c"), 5, nil, g("assassinate", "4a") },
	{ g("assassinate", "4f"), false, nil, nil, nil, nil, g("destroy_surpriseattack", "4e") },
}

-- The four mission heads and the four chain ends (the rewards move from the ends to the heads)
local HEADS = { g("recovery", "1a"), g("escort", "2a"), g("inspect", "3a"), g("assassinate", "4a") }
local ENDS = { g("assassinate", "1d"), g("rescue", "2e"), g("survival", "3c"), g("assassinate", "4f") }

-- Spec "Rewards" table; J line = the giveReward line of fixtures/script/conversation/naboo_privateer_tier3.java
local C = "object/tangible/ship/components/"
local REWARDS = {
	{ g("recovery", "1a"), "recovery", "naboo_privateer_tier3_1a", C .. "reactor/rct_mission_reward_neutral_subpro_military.iff", 228 },
	{ g("escort", "2a"), "escort", "naboo_privateer_tier3_2a", C .. "engine/eng_mission_reward_neutral_mandal_inferno.iff", 235 },
	{ g("inspect", "3a"), "inspect", "naboo_privateer_tier3_3a", C .. "weapon_capacitor/cap_mission_reward_neutral_sorosuub_v1.iff", 242 },
	{ g("assassinate", "4a"), "assassinate", "naboo_privateer_tier3_4a", C .. "armor/arm_mission_reward_neutral_kse_handcrafted.iff", 249 },
}

-- The globals Dulios can reach (invariant I-2, rsf-tier3-renames I-2/I-5): the 14 of table W plus delivery_no_pickup 3b
-- and the surprise attacks 4c, 4d, 4e. That is 18 distinct tables (the 18 chain members of rsf-tier3-renames I-5).
local DULIOS_REACHABLE = {
	g("recovery", "1a"), g("patrol", "1b"), g("destroy_surpriseattack", "1c"), g("assassinate", "1d"),
	g("escort", "2a"), g("destroy_surpriseattack", "2c"), g("space_battle", "2d"), g("rescue", "2e"),
	g("inspect", "3a"), g("survival", "3c"), g("destroy_surpriseattack", "3e"),
	g("assassinate", "4a"), g("space_battle", "4b"), g("assassinate", "4f"),
	g("delivery_no_pickup", "3b"), g("destroy_surpriseattack", "4c"), g("destroy_surpriseattack", "4d"), g("destroy_surpriseattack", "4e"),
}

local function quest(global) return H.expectGlobal(global, "RSF tier 3 quest table") end

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local text = f:read("a")
	f:close()
	return text
end

local function sortedKeys(t)
	local keys = {}

	for k in pairs(t) do
		keys[#keys + 1] = k
	end

	table.sort(keys)
	return keys
end

local function fixtureOf(global)
	local q = quest(global)

	return H.questFixture(q.questType, q.questName)
end

local function point(zone, name)
	local p = H.patrolPoints(zone)[name]

	assert(p ~= nil, "patrol point " .. tostring(name) .. " not found in " .. tostring(zone))
	return p
end

-- Spawns of a destroy_surpriseattack fixture by SWG's spawn loop (shipType row 1, shipCount); see rsf-tier4 Q3.
local function surpriseSpawns(rec)
	return { { count = rec:num("shipCount"), shipName = rec:get("shipType") } }
end

---------------------------------------------------------------------------------------------
-- AC-1: rewards move to the four mission heads
---------------------------------------------------------------------------------------------

TestRsfTier3Rewards = {}

function TestRsfTier3Rewards:setUp() H.reset() end

-- AC-1: the spec's reward table agrees with the giveReward lines of the SWG Dulios script.
function TestRsfTier3Rewards:test_the_spec_reward_table_matches_the_giveReward_lines_of_the_swg_dulios_script()
	local lines = {}

	for line in readFile(H.FIXTURES .. "script/conversation/naboo_privateer_tier3.java"):gmatch("([^\n]*)\n") do
		lines[#lines + 1] = line
	end

	for _, row in ipairs(REWARDS) do
		local text = lines[row[5]]

		lu.assertNotNil(text, row[1] .. ": J line " .. row[5] .. " exists")

		local questType, questName, credits, item = text:match('giveReward%(player, "([^"]+)", "([^"]+)", (%d+), "([^"]+)"%)')

		lu.assertEquals({ questType, questName, tonumber(credits), item }, { row[2], row[3], 25000, row[4] }, row[1] .. ": J:" .. row[5] .. " giveReward")
	end
end

-- AC-1
function TestRsfTier3Rewards:test_each_mission_head_carries_25000_credits_and_its_component()
	for _, row in ipairs(REWARDS) do
		local q = quest(row[1])

		lu.assertEquals(q.creditReward, 25000, row[1] .. ": creditReward")
		lu.assertEquals(q.itemReward, { { species = { -1 }, item = row[4] } }, row[1] .. ": itemReward")
	end
end

-- AC-1
function TestRsfTier3Rewards:test_the_four_chain_ends_pay_nothing()
	for _, name in ipairs(ENDS) do
		local q = quest(name)

		lu.assertEquals(q.creditReward, 0, name .. ": creditReward")
		lu.assertEquals(q.itemReward, {}, name .. ": itemReward")
	end
end

-- AC-1, I-2: among the 18 Dulios-reachable globals exactly the four heads pay
function TestRsfTier3Rewards:test_exactly_the_four_heads_pay_among_the_dulios_reachable_tables()
	local heads = {}

	for _, name in ipairs(HEADS) do
		heads[name] = true
	end

	lu.assertEquals(#DULIOS_REACHABLE, 18, "setup: the reachable list (the 18 chain members)")

	for _, name in ipairs(DULIOS_REACHABLE) do
		local q = quest(name)

		if not heads[name] then
			lu.assertEquals(q.creditReward, 0, name .. ": creditReward (not a head)")
			lu.assertEquals(#(q.itemReward or {}), 0, name .. ": itemReward entries (not a head)")
		end
	end
end

-- AC-1: rewardPlayer on a head grants 25,000 credits and the listed item.
function TestRsfTier3Rewards:test_reward_player_on_each_head_grants_25000_credits_and_the_listed_item()
	for _, row in ipairs(REWARDS) do
		H.reset()

		local player = H.newPlayer({ name = "Ace" })
		local credits = H.spyOn(SpaceHelpers, "spaceCreditReward")
		local items = H.spyOn(SpaceHelpers, "spaceItemReward")

		quest(row[1]):rewardPlayer(player)

		lu.assertEquals(#credits, 1, row[1] .. ": spaceCreditReward calls")
		lu.assertIs(credits[1].args[1], player, row[1] .. ": credits go to the player")
		lu.assertEquals(credits[1].args[2], 25000, row[1] .. ": credit amount")
		lu.assertEquals(#items, 1, row[1] .. ": spaceItemReward calls")
		lu.assertIs(items[1].args[1], player, row[1] .. ": item goes to the player")
		lu.assertEquals(items[1].args[2], row[4], row[1] .. ": item path")
	end
end

-- AC-1: rewardPlayer on a chain end grants nothing (the reward is not paid twice).
function TestRsfTier3Rewards:test_reward_player_on_a_chain_end_grants_neither_credits_nor_an_item()
	for _, name in ipairs(ENDS) do
		H.reset()

		local player = H.newPlayer({ name = "Ace" })
		local credits = H.spyOn(SpaceHelpers, "spaceCreditReward")
		local items = H.spyOn(SpaceHelpers, "spaceItemReward")

		quest(name):rewardPlayer(player)

		lu.assertEquals(#credits, 0, name .. ": spaceCreditReward calls")
		lu.assertEquals(#items, 0, name .. ": spaceItemReward calls")
	end
end

-- AC-1 (R-4, already true today: the four components have server loot templates)
function TestRsfTier3Rewards:test_the_reward_components_have_server_templates()
	for _, row in ipairs(REWARDS) do
		local path = H.SCRIPTS .. row[4]:gsub("%.iff$", ".lua")

		lu.assertTrue(H.fileExists(path), row[1] .. ": server template " .. path .. " must exist")
	end
end

---------------------------------------------------------------------------------------------
-- AC-2 / I-3 / I-4: split wiring
---------------------------------------------------------------------------------------------

TestRsfTier3Wiring = {}

function TestRsfTier3Wiring:setUp() H.reset() end

-- AC-2: the fixtures carry the values spec table W was derived from.
function TestRsfTier3Wiring:test_the_fixtures_carry_the_trigger_values_the_spec_lists()
	local function trigger(dir, name)
		local rec = H.questFixture(dir, name)

		return { rec:get("triggerEvent"), rec:get("triggerSplitCondition"), rec:get("triggerArg"), rec:num("triggerOn"), rec:num("triggerDelay") }
	end

	lu.assertEquals(trigger("recovery", "naboo_privateer_tier3_1a"), { "splitquest", "success", "patrol:naboo_privateer_tier3_1b", 0, nil }, "recovery 1a")
	lu.assertEquals(trigger("patrol", "naboo_privateer_tier3_1b"), { "splitquest", "triggerOn", "destroy_surpriseattack:naboo_privateer_tier3_1c", 1, 44 }, "patrol 1b")
	lu.assertEquals(trigger("destroy_surpriseattack", "naboo_privateer_tier3_1c"), { "splitquest", "success", "assassinate:naboo_privateer_tier3_1d", 0, 0 }, "surprise attack 1c")
	lu.assertEquals(trigger("assassinate", "naboo_privateer_tier3_1d"), { "none", "triggerOn", nil, 0, nil }, "assassinate 1d")
	lu.assertEquals(trigger("escort", "naboo_privateer_tier3_2a"), { "splitquest", "success", "destroy_surpriseattack:naboo_privateer_tier3_2c", -1, 0 }, "escort 2a")
	lu.assertEquals(trigger("destroy_surpriseattack", "naboo_privateer_tier3_2c"), { "splitquest", "success", "space_battle:naboo_privateer_tier3_2d", -1, 0 }, "surprise attack 2c")
	lu.assertEquals(trigger("inspect", "naboo_privateer_tier3_3a"), { "splitquest", "success", "delivery_no_pickup:naboo_privateer_tier3_3b", -1, 5 }, "inspect 3a")
	lu.assertEquals(trigger("survival", "naboo_privateer_tier3_3c"), { "splitquest", "success", "destroy_surpriseattack:naboo_privateer_tier3_3e", -1, nil }, "survival 3c")
	lu.assertEquals(trigger("assassinate", "naboo_privateer_tier3_4a"), { "splitquest", "success", "space_battle:naboo_privateer_tier3_4b", -1, nil }, "assassinate 4a")
	lu.assertEquals(trigger("space_battle", "naboo_privateer_tier3_4b"), { "splitquest", "success", "destroy_surpriseattack:naboo_privateer_tier3_4c", -1, nil }, "space battle 4b")
	lu.assertEquals(trigger("assassinate", "naboo_privateer_tier3_4f"), { "none", "triggerOn", nil, 0, nil }, "assassinate 4f")
end

-- AC-2, I-4: every derived value equals the Core3 field (no exceptions after rsf-tier3-renames).
function TestRsfTier3Wiring:test_split_wiring_equals_the_fixture_by_the_spec_rules()
	for _, row in ipairs(W) do
		local name = row[1]
		local q = quest(name)
		local rec = fixtureOf(name)

		if rec:get("triggerEvent") == "splitquest" then
			local sideType, sideName = H.Tab.splitQuestRef(rec:get("triggerArg"))
			local delay = rec:num("triggerDelay") or 0

			lu.assertTrue(q.sideQuest, name .. ": sideQuest (triggerEvent=splitquest)")
			lu.assertEquals(q.sideQuestType, sideType, name .. ": sideQuestType (triggerArg)")
			lu.assertEquals(q.sideQuestName, sideName, name .. ": sideQuestName (triggerArg)")

			if rec:get("triggerSplitCondition") == "triggerOn" then
				lu.assertEquals(q.sideQuestSplitType, SPLIT.PATROL_POINT, name .. ": sideQuestSplitType (triggerOn split)")
				lu.assertEquals(q.sideQuestPatrolStart, rec:num("triggerOn"), name .. ": sideQuestPatrolStart (triggerOn)")
				lu.assertEquals(q.sideQuestDelay, delay, name .. ": sideQuestDelay (triggerDelay, patrol point split)")
			else
				lu.assertEquals(rec:get("triggerSplitCondition"), "success", name .. ": fixture split condition is the one this test maps")
				lu.assertEquals(q.sideQuestSplitType, SPLIT.COMPLETION, name .. ": sideQuestSplitType (success)")
				lu.assertEquals(q.sideQuestDelay, delay + 5, name .. ": sideQuestDelay (triggerDelay + 5, success split)")
			end
		else
			lu.assertEquals(rec:get("triggerEvent"), "none", name .. ": fixture triggerEvent")
			lu.assertFalse(q.sideQuest and true or false, name .. ": sideQuest (triggerEvent=none)")
			lu.assertEquals(q.sideQuestSplitType or SPLIT.NONE, SPLIT.NONE, name .. ": sideQuestSplitType (NONE or unset)")
		end
	end
end

-- AC-2: spec table W as literals (anchors for the fixture-derived test above).
function TestRsfTier3Wiring:test_spec_table_w_holds_field_by_field()
	for _, row in ipairs(W) do
		local name = row[1]
		local q = quest(name)

		lu.assertEquals(q.sideQuest and true or false, row[2], name .. ": sideQuest")

		if row[2] then
			lu.assertEquals(q.sideQuestSplitType, row[3], name .. ": sideQuestSplitType")
			lu.assertEquals(q.sideQuestType .. "_" .. q.sideQuestName, row[4], name .. ": side quest global")
			lu.assertEquals(q.sideQuestDelay, row[5], name .. ": sideQuestDelay")
			lu.assertEquals(q.sideQuestPatrolStart, row[6] or 0, name .. ": sideQuestPatrolStart")
		else
			lu.assertEquals(q.sideQuestSplitType or SPLIT.NONE, SPLIT.NONE, name .. ": sideQuestSplitType (none)")
		end
	end
end

-- AC-2, I-3: the parent fields name the quest that starts each table.
function TestRsfTier3Wiring:test_parent_fields_name_the_quest_whose_split_starts_each_table()
	for _, row in ipairs(W) do
		local name = row[1]
		local q = quest(name)
		local parent = row[7]

		if parent == "" then
			lu.assertEquals(q.parentQuest, "", name .. ": parentQuest (head)")
			lu.assertEquals(q.parentQuestType, "", name .. ": parentQuestType (head)")
			lu.assertEquals(q.parentQuestName, "", name .. ": parentQuestName (head)")
		else
			local p = quest(parent)

			lu.assertEquals(q.parentQuest, parent, name .. ": parentQuest")
			lu.assertEquals(q.parentQuestType, p.questType, name .. ": parentQuestType")
			lu.assertEquals(q.parentQuestName, p.questName, name .. ": parentQuestName")
		end
	end
end

-- I-3: every split points at an existing table, and that table names the splitting table back as its parent.
function TestRsfTier3Wiring:test_every_split_target_exists_and_names_its_splitting_table_as_parent()
	local tables = {}

	for _, row in ipairs(W) do
		tables[#tables + 1] = row[1]
	end

	-- rsf-tier3-renames (I-3, no exceptions): the four new tables take part in the chains too
	tables[#tables + 1] = g("delivery_no_pickup", "3b")
	tables[#tables + 1] = g("destroy_surpriseattack", "4c")
	tables[#tables + 1] = g("destroy_surpriseattack", "4d")
	tables[#tables + 1] = g("destroy_surpriseattack", "4e")

	for _, name in ipairs(tables) do
		local q = quest(name)

		if q.sideQuest then
			local target = q.sideQuestType .. "_" .. q.sideQuestName
			local t = rawget(_G, target)

			lu.assertNotNil(t, name .. ": split target global " .. target)
			lu.assertEquals(t.questName, q.sideQuestName, name .. ": sideQuestName equals the target's questName")
			lu.assertEquals(t.questType, q.sideQuestType, name .. ": sideQuestType equals the target's questType")
			lu.assertEquals(t.parentQuest, name, name .. ": the target " .. target .. " names it back as parentQuest")
		end
	end
end

-- rsf-tier3-renames (AC-3, Content contract 1): the three tables F2 replaces are deleted, not just renamed.
function TestRsfTier3Wiring:test_the_three_tables_f2_replaced_are_deleted_and_unregistered()
	for _, name in ipairs({ g("delivery", "3b"), g("survival", "4c"), g("destroy_surpriseattack", "4_initial") }) do
		lu.assertNil(rawget(_G, name), name .. ": global must be gone")
		lu.assertNil(H.registered(name), name .. ": registerScreenPlay must be gone")
	end
end

---------------------------------------------------------------------------------------------
-- I-1 identity, I-5 chains, AC-9
---------------------------------------------------------------------------------------------

TestRsfTier3Identity = {}

function TestRsfTier3Identity:setUp() H.reset() end

-- I-1 (rsf-tier3-renames): 163 minus the three deleted tables plus four new ones.
function TestRsfTier3Identity:test_the_set_of_space_quest_globals_has_the_f2_count()
	lu.assertEquals(#H.questGlobals(), 164, "number of space quest globals (CorSec, Havoc and RSF loaded)")
end

-- I-1
function TestRsfTier3Identity:test_every_tier3_table_keeps_its_class_name_type_name_and_registration()
	for _, name in ipairs(DULIOS_REACHABLE) do
		local q = quest(name)

		lu.assertEquals(q.className, name, name .. ": className")
		lu.assertEquals(q.questType .. "_" .. q.questName, name, name .. ": questType_questName")
		lu.assertNotNil(H.registered(name), name .. ": registerScreenPlay was called")
		lu.assertTrue(H.registered(name).start, name .. ": registered with start = true")
	end
end

-- I-5, AC-9
function TestRsfTier3Identity:test_the_four_chains_walk_from_each_head_in_order()
	local expected = {
		[g("recovery", "1a")] = { g("recovery", "1a"), g("patrol", "1b"), g("destroy_surpriseattack", "1c"), g("assassinate", "1d") },
		[g("escort", "2a")] = { g("escort", "2a"), g("destroy_surpriseattack", "2c"), g("space_battle", "2d"), g("rescue", "2e") },
		[g("inspect", "3a")] = { g("inspect", "3a"), g("delivery_no_pickup", "3b"), g("survival", "3c"), g("destroy_surpriseattack", "3e") },
		[g("assassinate", "4a")] = { g("assassinate", "4a"), g("space_battle", "4b"), g("destroy_surpriseattack", "4c"), g("destroy_surpriseattack", "4d"), g("destroy_surpriseattack", "4e"), g("assassinate", "4f") },
	}

	for _, head in ipairs(sortedKeys(expected)) do
		local names = {}

		for i, member in ipairs(SpaceHelpers:getSpaceQuestChain(head)) do
			names[i] = member.global
		end

		lu.assertEquals(names, expected[head], head .. ": chain")
	end
end

-- D-9 (F1): the invented points stayed in F1 and F3 deletes them together
-- (rsf-tier3-mission1-2-data AC-8 inverts this pin; the full list is in test_rsf_tier3_mission12_data.lua).
function TestRsfTier3Identity:test_the_invented_points_the_4a_and_4f_payload_orphans_are_deleted()
	for i = 1, 4 do
		lu.assertNil(H.patrolPoints("space_dantooine")["dantooine_privateer_tier3_beldini_" .. i], "dantooine_privateer_tier3_beldini_" .. i .. " deleted")
		lu.assertNil(H.patrolPoints("space_lok")["lok_privateer_tier3_krayt_bane_" .. i], "lok_privateer_tier3_krayt_bane_" .. i .. " deleted")
	end
end

---------------------------------------------------------------------------------------------
-- AC-3: 3e payload
---------------------------------------------------------------------------------------------

TestRsfTier3Mission3Ambush = {}

function TestRsfTier3Mission3Ambush:setUp() H.reset() end

-- AC-3
function TestRsfTier3Mission3Ambush:test_3e_spawns_what_the_swg_spawn_loop_spawns_for_its_fixture()
	local q = quest(g("destroy_surpriseattack", "3e"))
	local rec = fixtureOf(g("destroy_surpriseattack", "3e"))

	lu.assertEquals(rec:get("shipType"), "blacksun_marauder_tier3", "fixture anchor: shipType")
	lu.assertEquals(rec:num("shipCount"), 5, "fixture anchor: shipCount")
	lu.assertEquals(q.questZone, rec:get("questZone"), "3e: questZone")
	lu.assertEquals(q.surpriseAttackShips.zone, rec:get("questZone"), "3e: surpriseAttackShips.zone")
	lu.assertEquals(q.surpriseAttackShips.spawns, surpriseSpawns(rec), "3e: surpriseAttackShips.spawns (SWG spawn loop)")
end

-- AC-3
function TestRsfTier3Mission3Ambush:test_3e_literal_values()
	local q = quest(g("destroy_surpriseattack", "3e"))

	lu.assertEquals(q.questZone, "space_naboo", "3e: questZone")
	lu.assertEquals(q.surpriseAttackShips, { zone = "space_naboo", spawns = { { count = 5, shipName = "blacksun_marauder_tier3" } } }, "3e: surpriseAttackShips")
	lu.assertEquals(q.creditReward, 0, "3e: creditReward")
	lu.assertFalse(q.sideQuest and true or false, "3e: sideQuest")
	lu.assertEquals(q.parentQuest, g("survival", "3c"), "3e: parentQuest")
	lu.assertEquals({ q.parentQuestType, q.parentQuestName }, { "survival", "naboo_privateer_tier3_3c" }, "3e: parentQuestType, parentQuestName")
end

---------------------------------------------------------------------------------------------
-- AC-4: 4a and 4f payload
---------------------------------------------------------------------------------------------

TestRsfTier3Assassinations = {}

function TestRsfTier3Assassinations:setUp() H.reset() end

local ASSASSINATIONS = { g("assassinate", "4a"), g("assassinate", "4f") }

-- AC-4: the fixtures carry the values the spec lists.
function TestRsfTier3Assassinations:test_the_fixtures_carry_the_values_the_spec_lists()
	local a, f = fixtureOf(ASSASSINATIONS[1]), fixtureOf(ASSASSINATIONS[2])

	lu.assertEquals({ a:get("questZone"), a:get("targetShipType"), a:num("targetArrivalDelay"), #a:list("escortPath"), #a:list("targetEscort") }, { "space_dantooine", "blacksun_beldini_tier3", 45, 4, 4 }, "assassinate 4a")
	lu.assertEquals({ f:get("questZone"), f:get("targetShipType"), f:num("targetArrivalDelay"), #f:list("escortPath"), #f:list("targetEscort") }, { "space_lok", "blacksun_krayt_bane_tier3", 25, 3, 2 }, "assassinate 4f")
end

-- AC-4: zone, arrival delay, target, escorts and points equal the fixture.
function TestRsfTier3Assassinations:test_4a_and_4f_payload_equals_the_fixture()
	for _, name in ipairs(ASSASSINATIONS) do
		local q = quest(name)
		local rec = fixtureOf(name)

		lu.assertEquals(q.questZone, rec:get("questZone"), name .. ": questZone")
		lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), name .. ": arrivalDelay (targetArrivalDelay)")
		lu.assertEquals(q.assassinateSpawns.target, rec:get("targetShipType"), name .. ": assassinateSpawns.target")
		lu.assertEquals(q.assassinateSpawns.escorts, rec:list("targetEscort"), name .. ": assassinateSpawns.escorts (in order)")
		lu.assertEquals(q.failTimer, 20, name .. ": failTimer (Core3 choice, no SWG column)")

		local points = rec:list("escortPath")

		lu.assertEquals(#q.targetPatrols, #points, name .. ": number of targetPatrols")

		for i, value in ipairs(points) do
			local zone, pointName = H.Tab.splitNavPoint(value)
			local p = point(zone, pointName)

			lu.assertEquals(q.targetPatrols[i].patrolPointName, pointName, name .. ": targetPatrols[" .. i .. "].patrolPointName")
			lu.assertEquals({ q.targetPatrols[i].x, q.targetPatrols[i].z, q.targetPatrols[i].y }, { p.x, p.z, p.y }, name .. ": targetPatrols[" .. i .. "] coordinates (" .. zone .. " point " .. pointName .. ")")
			lu.assertEquals(zone, q.questZone, name .. ": escortPath zone equals questZone")
		end
	end
end

-- AC-4: the spec's literal payload.
function TestRsfTier3Assassinations:test_4a_literal_payload()
	local q = quest(g("assassinate", "4a"))

	lu.assertEquals(q.questZone, "space_dantooine", "4a: questZone")
	lu.assertEquals(q.arrivalDelay, 45, "4a: arrivalDelay")
	lu.assertEquals(q.failTimer, 20, "4a: failTimer")
	lu.assertEquals(q.assassinateSpawns, {
		target = "blacksun_beldini_tier3",
		escorts = { "blacksun_vehement_tier3", "blacksun_vehement_tier3", "blacksun_bomber_s03_tier3", "blacksun_bomber_s03_tier3" },
	}, "4a: assassinateSpawns")
	lu.assertEquals(q.targetPatrols, {
		{ patrolPointName = "naboo_privateer_tier3_leg_4_assassinate_1", x = 1595, z = 2985, y = 2864 },
		{ patrolPointName = "naboo_privateer_tier3_leg_4_assassinate_2", x = 1500, z = 4139, y = 1708 },
		{ patrolPointName = "naboo_privateer_tier3_leg_4_assassinate_3", x = 1420, z = 3841, y = -954 },
		{ patrolPointName = "naboo_privateer_tier3_leg_4_assassinate_4", x = 558, z = 2111, y = -569 },
	}, "4a: targetPatrols")
end

-- AC-4
function TestRsfTier3Assassinations:test_4f_literal_payload()
	local q = quest(g("assassinate", "4f"))

	lu.assertEquals(q.questZone, "space_lok", "4f: questZone")
	lu.assertEquals(q.arrivalDelay, 25, "4f: arrivalDelay")
	lu.assertEquals(q.failTimer, 20, "4f: failTimer")
	lu.assertEquals(q.assassinateSpawns, {
		target = "blacksun_krayt_bane_tier3",
		escorts = { "blacksun_ace_s04_tier3", "blacksun_ace_s04_tier3" },
	}, "4f: assassinateSpawns")
	lu.assertEquals(q.targetPatrols, {
		{ patrolPointName = "hostage_escort_5", x = -3467, z = 2588, y = -6633 },
		{ patrolPointName = "hostage_recovery_1", x = -2930, z = 2690, y = -4742 },
		{ patrolPointName = "hostage_recovery_5", x = -5082, z = 2428, y = -476 },
	}, "4f: targetPatrols")
end
