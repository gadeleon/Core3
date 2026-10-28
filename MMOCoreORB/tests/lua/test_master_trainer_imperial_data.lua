-- Imperial master trainer: the two Kessel quest tables against the SWG-Source fixtures, the assets and the client journal.
-- Spec: .claude/work/space-master-trainer-imperial/01-spec.md (AC-2; invariants I-1 to I-5; Data mapping).
--
-- Scalars come from the spec (master_trainer_imperial_data.lua); the ship lists come from the .tab fixtures by the Data mapping rule. Ship
-- templates are read from ship_mobile/ships on disk; the one named exception is rebel_smuggler_tier5 (D-7).

local lu = require("luaunit")
local H = require("harness")
local M = require("master_trainer_imperial_data")

M.load()

local NO_TEMPLATE = "rebel_smuggler_tier5"

local function readFile(path)
	local f = io.open(path, "r")

	if f == nil then
		return nil
	end

	local text = f:read("a")

	f:close()
	return text
end

local function sortedKeys(t)
	local keys = {}

	for k in pairs(t) do
		keys[#keys + 1] = tostring(k)
	end

	table.sort(keys)
	return keys
end

local function ownKeys(q)
	local own = {}

	for k, v in pairs(q) do
		own[k] = v
	end

	return own
end

local function inherits(q, class)
	local mt = getmetatable(q)

	for _ = 1, 8 do
		if mt == nil then
			return false
		end

		if mt == class or mt.__index == class then
			return true
		end

		mt = getmetatable(mt.__index)
	end

	return false
end

TestMasterTrainerImperialFixtures = {}

function TestMasterTrainerImperialFixtures:setUp() H.reset() end

-- AC-2 (the oracle itself): the fixture copies carry the values the spec lists
function TestMasterTrainerImperialFixtures:test_the_fixtures_carry_the_values_the_spec_lists()
	local one, two = M.fixtureOf("destroy_master_imperial_1"), M.fixtureOf("destroy_master_imperial_2")

	lu.assertEquals(one:get("questZone"), "space_light1", "master_imperial_1: questZone")
	lu.assertEquals(one:num("killCount"), 30, "master_imperial_1: killCount")
	lu.assertEquals(one:num("killVariance"), 0, "master_imperial_1: killVariance")
	lu.assertEquals(one:num("giveSpawnWaypoint"), 0, "master_imperial_1: giveSpawnWaypoint")
	lu.assertEquals(one:num("spawnsForWaypointsOnly"), 0, "master_imperial_1: spawnsForWaypointsOnly")
	lu.assertEquals(one:list("validSpawns"), {}, "master_imperial_1: validSpawns")
	lu.assertEquals(one:list("shipList"), {
		"reb_awing_tier5", "reb_bwing_tier5", "reb_gunboat_tier5", "reb_kessel_lootboat_tier5", "reb_xwing_tier5", "reb_ywing_tier5", "reb_z95_tier5", "rebel_smuggler_tier5",
	}, "master_imperial_1: shipList (8 names, .tab order)")

	lu.assertEquals(two:get("questZone"), "space_light1", "master_imperial_2: questZone")
	lu.assertEquals(two:num("killCount"), 1, "master_imperial_2: killCount")
	lu.assertEquals(two:num("giveSpawnWaypoint"), 0, "master_imperial_2: giveSpawnWaypoint")
	lu.assertEquals(two:num("spawnsForWaypointsOnly"), 0, "master_imperial_2: spawnsForWaypointsOnly")
	lu.assertEquals(two:list("validSpawns"), { "space_light1:corvette_convoy_rebel" }, "master_imperial_2: validSpawns")
	lu.assertEquals(two:list("shipList"), { "reb_corellian_corvette_tier4" }, "master_imperial_2: shipList")

	for _, rec in ipairs({ one, two }) do
		lu.assertEquals(rec:get("triggerEvent"), "none", "triggerEvent")
		lu.assertEquals(rec:num("autoReward"), 0, "autoReward")
		lu.assertEquals(rec:num("questDelay"), 0, "questDelay")
		lu.assertEquals(rec:get("questSeries"), "pilot_profession", "questSeries")
	end
end

-- I-1: identity
function TestMasterTrainerImperialFixtures:test_each_table_keeps_its_identity_zone_and_destroy_base_type()
	for _, global in ipairs(M.GLOBALS) do
		local q = M.quest(global)
		local want = M.QUESTS[global]

		lu.assertEquals(rawget(q, "className"), global, global .. ": className")
		lu.assertEquals(rawget(q, "questType"), want.type, global .. ": questType")
		lu.assertEquals(rawget(q, "questName"), want.name, global .. ": questName")
		lu.assertEquals(rawget(q, "questZone"), "space_light1", global .. ": questZone")
		lu.assertTrue(inherits(q, SpaceDestroyScreenplay), global .. ": is a SpaceDestroyScreenplay")
	end
end

-- I-2, AC-2: the whole table, every key, and no other key
function TestMasterTrainerImperialFixtures:test_each_table_equals_the_contract_and_sets_no_other_key()
	local want = M.expected()

	for _, global in ipairs(M.GLOBALS) do
		local q = M.quest(global)

		lu.assertEquals(sortedKeys(ownKeys(q)), sortedKeys(want[global]), global .. ": own keys")

		for key, value in pairs(want[global]) do
			lu.assertEquals(rawget(q, key), value, global .. ": " .. key)
		end
	end
end

-- I-2, AC-2: conformance, field by field, with the quest and field in the message
function TestMasterTrainerImperialFixtures:test_every_mapped_field_equals_the_value_the_fixture_gives()
	for _, global in ipairs(M.GLOBALS) do
		local q = M.quest(global)
		local label = M.QUESTS[global].name
		local rec = M.fixtureOf(global)

		lu.assertEquals(rawget(q, "questZone"), rec:get("questZone"), label .. ": questZone")
		lu.assertEquals(rawget(q, "shipTypes"), rec:list("shipList"), label .. ": shipTypes (shipList, order and length)")
		lu.assertEquals(rawget(q, "killsRequired"), rec:num("killCount"), label .. ": killsRequired (killCount, variance 0)")
		lu.assertEquals(rec:num("giveSpawnWaypoint"), 0, label .. ": giveSpawnWaypoint (no waypoint)")
		lu.assertEquals(rawget(q, "shipLocations"), {}, label .. ": shipLocations (no waypoint, as in SWG)")
		lu.assertEquals(rawget(q, "sideQuest"), false, label .. ": sideQuest")
		lu.assertEquals(rawget(q, "sideQuestType"), "", label .. ": sideQuestType")
	end
end

-- I-2: mission 1 lists the 8 names, mission 2 the corvette
function TestMasterTrainerImperialFixtures:test_mission_1_has_thirty_kills_of_eight_ships_and_mission_2_one_corvette_kill()
	local one, two = M.quest("destroy_master_imperial_1"), M.quest("destroy_master_imperial_2")

	lu.assertEquals(one.killsRequired, 30, "master_imperial_1: killsRequired")
	lu.assertEquals(#one.shipTypes, 8, "master_imperial_1: shipTypes length")
	lu.assertEquals(two.killsRequired, 1, "master_imperial_2: killsRequired")
	lu.assertEquals(two.shipTypes, { "reb_corellian_corvette_tier4" }, "master_imperial_2: shipTypes")
end

-- I-3: every ship names a template on disk, except the one named exception
function TestMasterTrainerImperialFixtures:test_every_ship_but_the_one_named_exception_has_a_template_file()
	local ships = {}

	for _, global in ipairs(M.GLOBALS) do
		for _, name in ipairs(M.quest(global).shipTypes) do
			ships[#ships + 1] = name
		end
	end

	lu.assertEquals(#ships, 9, "ships named by the two tables")

	for _, name in ipairs(ships) do
		local path = H.SCRIPTS .. "ship_mobile/ships/" .. name .. ".lua"

		if name == NO_TEMPLATE then
			lu.assertFalse(H.fileExists(path), name .. " has no Core3 template (D-7): if it exists now, update the spec and this exception")
		else
			lu.assertTrue(H.fileExists(path), "ship_mobile/ships/" .. name .. ".lua does not exist")
		end
	end
end

-- I-3: the ship templates the kills match are the real templates' names (a template registers under the name the quest lists)
function TestMasterTrainerImperialFixtures:test_the_listed_ship_templates_register_under_the_listed_names()
	for _, global in ipairs(M.GLOBALS) do
		for _, name in ipairs(M.quest(global).shipTypes) do
			if name ~= NO_TEMPLATE then
				lu.assertNotNil(H.shipTemplate(name), global .. ": ship_mobile/ships/" .. name .. ".lua registers no template of that name")
			end
		end
	end
end

-- I-3: the reward items have object templates
function TestMasterTrainerImperialFixtures:test_both_reward_items_have_object_templates_under_wearables()
	for _, global in ipairs(M.GLOBALS) do
		for _, entry in ipairs(M.quest(global).itemReward) do
			lu.assertNotNil(entry.item:match("^object/tangible/wearables/"), global .. ": item " .. entry.item .. " is a wearable")
			lu.assertTrue(H.fileExists(H.SCRIPTS .. entry.item:gsub("%.iff$", ".lua")), global .. ": " .. entry.item .. ": no object template under bin/scripts")
		end
	end
end

-- I-4: rewards
function TestMasterTrainerImperialFixtures:test_the_rewards_are_25000_with_the_jacket_and_50000_with_the_helmet_for_any_species()
	local one, two = M.quest("destroy_master_imperial_1"), M.quest("destroy_master_imperial_2")

	lu.assertEquals(one.creditReward, 25000, "master_imperial_1: creditReward")
	lu.assertEquals(one.itemReward, { { species = { -1 }, item = "object/tangible/wearables/jacket/jacket_ace_imperial.iff" } }, "master_imperial_1: itemReward")
	lu.assertEquals(two.creditReward, 50000, "master_imperial_2: creditReward")
	lu.assertEquals(two.itemReward, { { species = { -1 }, item = "object/tangible/wearables/helmet/helmet_fighter_imperial_ace.iff" } }, "master_imperial_2: itemReward")
end

-- I-4: the java answer key pays exactly these amounts
function TestMasterTrainerImperialFixtures:test_the_reward_literals_match_the_swg_trainer_script()
	local java = readFile(H.FIXTURES .. "script/conversation/imperial_master_trainer.java")

	lu.assertNotNil(java, "fixtures/script/conversation/imperial_master_trainer.java")

	local function body(name)
		return java:match("void imperial_master_trainer_action_" .. name .. "%b()[^{]*(%b{})")
	end

	local one, two = body("giveRewardOneImp"), body("giveRewardTwoImp")

	lu.assertNotNil(one, "J giveRewardOneImp")
	lu.assertNotNil(two, "J giveRewardTwoImp")
	lu.assertNotNil(one:find("25000", 1, true), "J:242-247 pays 25000")
	lu.assertNotNil(one:find("jacket_ace_imperial", 1, true), "J:242-247 gives the jacket")
	lu.assertNotNil(one:find("200", 1, true), "J:242-247 adds 200 standing")
	lu.assertNotNil(two:find("50000", 1, true), "J:248-255 pays 50000")
	lu.assertNotNil(two:find("helmet_fighter_imperial_ace", 1, true), "J:248-255 gives the helmet")
	lu.assertNotNil(two:find("400", 1, true), "J:248-255 adds 400 standing")
end

-- D-5: J grants the master skill with no XP charge
function TestMasterTrainerImperialFixtures:test_the_master_skill_is_free_in_the_swg_script_and_the_skill_row_lists_the_four_04_skills()
	local java = readFile(H.FIXTURES .. "script/conversation/imperial_master_trainer.java")

	lu.assertNotNil(java:find("noisyGrantSkill", 1, true), "J grants the master skill with skill.noisyGrantSkill")
	lu.assertNil(java:find("purchaseSkill", 1, true), "J never calls skill.purchaseSkill (D-5: no XP is charged)")

	local rec

	for _, r in ipairs(H.fixture("skill/skills.pilot_imperial_navy_master.tab").records) do
		if r:get("NAME") == "pilot_imperial_navy_master" then
			rec = r
		end
	end

	lu.assertNotNil(rec, "skills excerpt: the master row")
	lu.assertEquals(rec:get("SKILLS_REQUIRED"), "pilot_imperial_navy_starships_04,pilot_imperial_navy_weapons_04,pilot_imperial_navy_procedures_04,pilot_imperial_navy_droid_04",
		"skills.tab: SKILLS_REQUIRED of the master box")
	lu.assertEquals(rec:num("XP_COST"), 7500000, "skills.tab: XP_COST (listed, never charged by J)")
end

-- I-5: the client resolves each journal entry through misc/quest_crc_string_table
function TestMasterTrainerImperialFixtures:test_both_quests_are_in_the_client_quest_name_table()
	local text = readFile(H.FIXTURES .. "misc/quest_crc_string_table.names")

	lu.assertNotNil(text, "fixtures/misc/quest_crc_string_table.names")

	local set = {}

	for line in text:gmatch("[^\n]+") do
		set[line] = true
	end

	for _, global in ipairs(M.GLOBALS) do
		local q = M.QUESTS[global]
		local name = "spacequest/" .. q.type .. "/" .. q.name

		lu.assertTrue(set[name] == true, name .. " is not in the client quest table")
	end
end
